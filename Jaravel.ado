program Jaravel, eclass sortpreserve
	version 17.0
	syntax varlist(numeric fv) [if] [in], entity(string) time(string) spellvar(string) treatment(string) [we(string) fixed(string)]
	marksample touse
	
	tempname bCardinal bNonCardinal coeffs
	tempfile tFile
	tempvar county_fe year_fe cons y0 yDiff employmentAcrossIndex yDiffWeighted tautemp r x1 FirstTreat spellDur w
	gettoken depvar indepvar: varlist
	_fv_check_depvar `depvar'
	local len: word count `fixed'
	
	if "`we'"=="" {
		qui gen double `w' = 1
	} 
	else {
		qui gen double `w' = `we'
	}
	
	qui gen double `x1' = `time' if `spellvar'>=1
	bysort `entity': egen double `FirstTreat' = min(`x1')
	qui gen double `spellDur' = `time' - `FirstTreat'
	
	qui reghdfe `depvar' `indepvar' if `spellvar'==0 & `touse' ///
		[fweight=`w'], ///
		absorb(`entity' `time' `fixed', savefe) res(`r')
	predict `cons', xb
	
	qui sort `entity' __hdfe1__
	by `entity': replace __hdfe1__ = __hdfe1__[1]
	qui sort `time' __hdfe2__
	by `time': replace __hdfe2__ = __hdfe2__[1]
	
	local s = 2
	while (`s'<`len'+2) {
		local ++s
		gettoken varx fixed:fixed
		qui sort `varx' __hdfe`s'__
		by `varx': replace __hdfe`s'__ = __hdfe`s'__[1]
	}

	egen double `y0' = rowtotal(`cons' __hdfe1__-__hdfe`s'__)
	gen testVar = `y0'
	qui gen double `yDiff' = `depvar' -`y0'
	matrix `bCardinal' = J(1,31,.)
	local t = 1
	foreach x of numlist -6/8 {
		if `x'<0 {
			qui sum `yDiff' [fweight = `w'] if `spellDur'==`x' & `touse'
			matrix `bCardinal'[1,`t'] = r(mean)
		}
		else {
			qui reg `yDiff' `treatment' [fweight = `w'] if `spellvar'==1 & `spellDur'==`x' & `touse', nocons
			matrix `bCardinal'[1,`t'] = _b[`treatment']
		}
		local ++t
	}
	
	preserve 
	qui collapse `yDiff' [fweight = `w'] if `spellvar'<=1 & `spellDur'<=8 & `spellDur'>=-6 & `touse', by(`treatment' `spellDur')
	qui save `tFile', replace
	restore
	preserve
	qui collapse (sum) `w' if `spellvar'<=1 & `spellDur'>=-6 & `spellDur'<=8 & `touse', by(`treatment' `spellDur')
	qui merge 1:1 `treatment' `spellDur' using `tFile', nogen
	local t = 16
	foreach x of numlist -6/8 {
		egen double `employmentAcrossIndex' = total(`w') if `spellDur'==`x'
		qui gen double `yDiffWeighted' = (`yDiff'*`w')/(`employmentAcrossIndex'*`treatment') if `spellDur'==`x'
		replace `yDiffWeighted' = (`yDiff'*`w')/(`employmentAcrossIndex') if `x'<0
		egen double `tautemp' = total(`yDiffWeighted')
		qui sum `tautemp'
		matrix `bCardinal'[1,`t'] = r(mean) 
		drop `employmentAcrossIndex' `yDiffWeighted' `tautemp'
		local ++t
	}

	egen double `employmentAcrossIndex' = total(`w') if `spellDur'>=0 & `spellDur'<=7
	qui gen double `yDiffWeighted' = (`yDiff'*`w')/(`employmentAcrossIndex'*`treatment') if `spellDur'>=0 & `spellDur'<=7
	egen double `tautemp' = total(`yDiffWeighted')
	qui sum `tautemp'
	matrix `bCardinal'[1,`t'] = r(mean) 
	drop `employmentAcrossIndex' `yDiffWeighted' `tautemp'
	restore
	matrix `coeffs' = `bCardinal'

	ereturn post `coeffs', esample(`touse')
	ereturn display
end 
