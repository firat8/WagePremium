{smcl}
{* *! version 16.0 15jul2020}{...}
{viewerdialog Jaravel "dialog Jaravel"}{...}
{viewerjumpto "Syntax" "Jaravel##syntax"}{...}
{viewerjumpto "Description" "Jaravel##description"}{...}
{viewerjumpto "Options" "Jaravel##options"}{...}

{p2col:{bf:Jaravel}}Run Borusyak and Jaravel estimation

{marker syntax}{...}
{title:Syntax}
{p}
{cmd:Jaravel} {varlist}{cmd:,} {opt entity(variable) time(variable) spell(variable) treatment(variable)} [{opt we(variable)}]

{marker description}{...}
{title:Description}
{pstd}
{cmd:Jaravel} runs the imputation estimator in Jaravel, Borusyak, and Spiess. You have to provide the following as options. The {it:entity} variable (e.g. the state identifier), the {it:time} variable (e.g., the year), the treatment, a counter of the cumulative number of treatments (spell) and - if desired - a weighting variable (e.g., the state populations).

{marker options}{...}
{title:Options}
{phang}{opt entity(variable)} is required. It specifies the entity identifiers to use as fixed effects.

{phang}{opt time(variable)} is required. It specifies the time identifiers to use as fixed effects.

{phang}{opt treatment(variable)} is required. It contains the treatment intensity. 

{phang}{opt spell(variable)} is required. It contains the cumulative count of treatment spells, e.g., it is 0 before any treatment, 1 after the first treatment starts, 2 after another change in treatment intensity, etc.

{phang}{opt spell(variable)} is required. It contains the cumulative count of treatment spells, e.g., it is 0 before any treatment, 1 after the first treatment starts, 2 after another change in treatment intensity, etc. 

{phang}{opt we(variable)} is optional, and specifies the variable containing weights.

