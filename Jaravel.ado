program Jaravel, eclass sortpreserve
	version 17.0
	syntax varlist(numeric fv) [if] [in], entity(string) time(string) spellvar(string) treatment(string) [we(string)]
	marksample touse
	
	tempname bCardinal bNonCardinal coeffs
	tempvar county_fe year_fe cons y0 yDiff employmentAcrossIndex yDiffWeighted tautemp r x1 FirstTreat spellDur w
	gettoken depvar indepvar: varlist
	_fv_check_depvar `depvar'
	
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
		absorb(`county_fe' = `entity' `year_fe' = `time') res(`r')
	predict `cons', xb
	

	qui sort `entity' `time'
	by `entity': replace `county_fe' = `county_fe'[1]
	qui sort `time' `year_fe'
	by `time': replace `year_fe' = `year_fe'[1]
	qui gen double `y0' = `cons' + `year_fe' + `county_fe'
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
	qui save "tempData/yDiff", replace
	restore
	preserve
	qui collapse (sum) `w' if `spellvar'<=1 & `spellDur'>=-6 & `spellDur'<=8 & `touse', by(`treatment' `spellDur')
	qui merge 1:1 `treatment' `spellDur' using "tempData/yDiff", nogen
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
