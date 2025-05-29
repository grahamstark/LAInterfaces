#

tot = 0

obs = Observable( Monitor.Progress( UUIDs.uuid4(),"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
end

# included_capital = WealthSet([net_financial_wealth,net_physical_wealth])


mutable struct LASubsys{T}
    uuid :: UUID
    systype :: SystemType    
    income_living_allowance :: T       
    income_partners_allowance   :: T        
    income_other_dependants_allowance :: T  
    income_child_allowance   :: T   
    include_mortgage_repayments :: Bool
    INCOME_SUPPORT_passported :: Bool
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_passported :: Bool
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE_passported  :: Bool
    UNIVERSAL_CREDIT_passported  :: Bool 
    net_financial_wealth :: Bool
    net_physical_wealth :: Bool
    net_housing_wealth :: Bool    
    second_homes :: Bool
    income_contribution_rates :: Vector{T}
    income_contribution_limits :: Vector{T}  
    capital_contribution_rates :: Vector{T}
    capital_contribution_limits :: Vector{T} 
    
    prem_family :: T # = 0.0 # 22.00 # FIXME this is not used??
    prem_family_lone_parent :: T
    prem_disabled_child :: T # = 64.19
    prem_carer_single :: T # = 36.85
    prem_carer_couple :: T # = 73.70 # FIXME is this used?
    prem_disability_single :: T # = 34.35
    prem_disability_couple :: T # = 48.95
    uc_limit :: T
    uc_limit_type :: UCLimitType
    uc_use_earnings :: UCEarningsType

    housing_is_flat :: Bool
    housing_v :: T
    housing_max :: T

    childcare_is_flat :: Bool
    childcare_v :: T
    childcare_max :: T

    work_expenses_is_flat :: Bool
    work_expenses_v :: T
    work_expenses_max :: T

    maintenance_is_flat :: Bool
    maintenance_v :: T
    maintenance_max :: T

    repayments_is_flat :: Bool
    repayments_v :: T
    repayments_max :: T

    wealth_method :: ExtraDataMethod
    do_dodgy_takeup_corrections :: Bool
    reset_all_if_changed :: Bool

    ANY_OTHER_NI_OR_STATE_BENEFIT_disregarded :: Bool
    ARMED_FORCES_COMPENSATION_SCHEME_disregarded :: Bool
    ATTENDANCE_ALLOWANCE_disregarded :: Bool
    BASIC_INCOME_disregarded :: Bool
    BEREAVEMENT_ALLOWANCE_disregarded :: Bool
    CARERS_ALLOWANCE_disregarded :: Bool
    CHILD_BENEFIT_disregarded :: Bool
    CHILD_TAX_CREDIT_disregarded :: Bool
    CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_disregarded :: Bool
    CONTRIB_JOBSEEKERS_ALLOWANCE_disregarded :: Bool
    COUNCIL_TAX_BENEFIT_disregarded :: Bool
    DISCRETIONARY_HOUSING_PAYMENT_disregarded :: Bool
    DLA_MOBILITY_disregarded :: Bool
    DLA_SELF_CARE_disregarded :: Bool
    EDUCATION_ALLOWANCES_disregarded :: Bool
    FOSTER_CARE_PAYMENTS_disregarded :: Bool
    FREE_SCHOOL_MEALS_disregarded :: Bool
    FRIENDLY_SOCIETY_BENEFITS_disregarded :: Bool
    FUNERAL_GRANT_disregarded :: Bool
    GOVERNMENT_TRAINING_ALLOWANCES_disregarded :: Bool
    GUARDIANS_ALLOWANCE_disregarded :: Bool
    HOUSING_BENEFIT_disregarded :: Bool
    INCAPACITY_BENEFIT_disregarded :: Bool
    INCOME_SUPPORT_disregarded :: Bool
    INDUSTRIAL_INJURY_BENEFIT_disregarded :: Bool
    MATERNITY_ALLOWANCE_disregarded :: Bool
    MATERNITY_GRANT_disregarded :: Bool
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_disregarded :: Bool
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE_disregarded :: Bool
    OTHER_BENEFITS_disregarded :: Bool
    PENSION_CREDIT_disregarded :: Bool
    PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING_disregarded :: Bool
    PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY_disregarded :: Bool
    SAVINGS_CREDIT_disregarded :: Bool
    CARERS_ALLOWANCE_SUPPLEMENT_disregarded :: Bool
    SCOTTISH_CHILD_PAYMENT_disregarded :: Bool
    CHILD_DISABILITY_PAYMENT_CARE_disregarded :: Bool
    CHILD_DISABILITY_PAYMENT_MOBILITY_disregarded :: Bool
    PENSION_AGE_DISABILITY_disregarded :: Bool
    ADP_DAILY_LIVING_disregarded :: Bool
    ADP_MOBILITY_disregarded :: Bool
    SEVERE_DISABILITY_ALLOWANCE_disregarded :: Bool
    STATE_PENSION_disregarded :: Bool
    STUDENT_GRANTS_disregarded :: Bool
    STUDENT_LOANS_disregarded :: Bool
    UNIVERSAL_CREDIT_disregarded :: Bool
    WAR_WIDOWS_PENSION_disregarded :: Bool
    WIDOWS_PAYMENT_disregarded :: Bool
    WINTER_FUEL_PAYMENTS_disregarded :: Bool
    WORKING_TAX_CREDIT_disregarded :: Bool
end

mutable struct AllLASubsys{T}
    civil :: LASubsys{T}
    aa    :: LASubsys{T}
end
  
function LASubsys( uuid :: UUID, sys :: OneLegalAidSys )
    LASubsys(
        uuid, 
        sys.systype,
        sys.income_living_allowance,
        sys.income_partners_allowance,        
        sys.income_other_dependants_allowance,
        sys.income_child_allowance,
        sys.include_mortgage_repayments,
        INCOME_SUPPORT in sys.passported_benefits,
        NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE in sys.passported_benefits,
        NON_CONTRIB_JOBSEEKERS_ALLOWANCE in sys.passported_benefits, 
        UNIVERSAL_CREDIT in sys.passported_benefits,
        net_financial_wealth in sys.included_capital,
        net_physical_wealth in sys.included_capital,
        net_housing_wealth in sys.included_capital,
        second_homes in sys.included_capital,
        sys.income_contribution_rates,
        sys.income_contribution_limits,
        sys.capital_contribution_rates,
        sys.capital_contribution_limits,

        sys.premia.family,
        sys.premia.family_lone_parent,
        sys.premia.disabled_child,
        sys.premia.carer_single,
        sys.premia.carer_couple,
        sys.premia.disability_single,
        sys.premia.disability_couple,
        sys.uc_limit,
        sys.uc_limit_type,
        sys.uc_use_earnings,

        sys.expenses.housing.is_flat,
        sys.expenses.housing.v,
        sys.expenses.housing.max,

        sys.expenses.childcare.is_flat,
        sys.expenses.childcare.v,
        sys.expenses.childcare.max,

        sys.expenses.work_expenses.is_flat,
        sys.expenses.work_expenses.v,
        sys.expenses.work_expenses.max,

        sys.expenses.maintenance.is_flat,
        sys.expenses.maintenance.v,
        sys.expenses.maintenance.max,

        sys.expenses.repayments.is_flat,
        sys.expenses.repayments.v,
        sys.expenses.repayments.max,

        DEFAULT_SETTINGS.wealth_method,
        DEFAULT_SETTINGS.do_dodgy_takeup_corrections,
        false,
        ! (ANY_OTHER_NI_OR_STATE_BENEFIT in sys.incomes.included),
        ! (ARMED_FORCES_COMPENSATION_SCHEME in sys.incomes.included),
        ! (ATTENDANCE_ALLOWANCE in sys.incomes.included),
        ! (BASIC_INCOME in sys.incomes.included),
        ! (BEREAVEMENT_ALLOWANCE in sys.incomes.included),
        ! (CARERS_ALLOWANCE in sys.incomes.included),
        ! (CHILD_BENEFIT in sys.incomes.included),
        ! (CHILD_TAX_CREDIT in sys.incomes.included),
        ! (CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE in sys.incomes.included),
        ! (CONTRIB_JOBSEEKERS_ALLOWANCE in sys.incomes.included),
        ! (COUNCIL_TAX_BENEFIT in sys.incomes.included),
        ! (DISCRETIONARY_HOUSING_PAYMENT in sys.incomes.included),
        ! (DLA_MOBILITY in sys.incomes.included),
        ! (DLA_SELF_CARE in sys.incomes.included),
        ! (EDUCATION_ALLOWANCES in sys.incomes.included),
        ! (FOSTER_CARE_PAYMENTS in sys.incomes.included),
        ! (FREE_SCHOOL_MEALS in sys.incomes.included),
        ! (FRIENDLY_SOCIETY_BENEFITS in sys.incomes.included),
        ! (FUNERAL_GRANT in sys.incomes.included),
        ! (GOVERNMENT_TRAINING_ALLOWANCES in sys.incomes.included),
        ! (GUARDIANS_ALLOWANCE in sys.incomes.included),
        ! (HOUSING_BENEFIT in sys.incomes.included),
        ! (INCAPACITY_BENEFIT in sys.incomes.included),
        ! (INCOME_SUPPORT in sys.incomes.included),
        ! (INDUSTRIAL_INJURY_BENEFIT in sys.incomes.included),
        ! (MATERNITY_ALLOWANCE in sys.incomes.included),
        ! (MATERNITY_GRANT in sys.incomes.included),
        ! (NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE in sys.incomes.included),
        ! (NON_CONTRIB_JOBSEEKERS_ALLOWANCE in sys.incomes.included),
        ! (OTHER_BENEFITS in sys.incomes.included),
        ! (PENSION_CREDIT in sys.incomes.included),
        ! (PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING in sys.incomes.included),
        ! (PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY in sys.incomes.included),
        ! (SAVINGS_CREDIT in sys.incomes.included),
        ! (CARERS_ALLOWANCE_SUPPLEMENT in sys.incomes.included),
        ! (SCOTTISH_CHILD_PAYMENT in sys.incomes.included),
        ! (CHILD_DISABILITY_PAYMENT_CARE in sys.incomes.included),
        ! (CHILD_DISABILITY_PAYMENT_MOBILITY in sys.incomes.included),
        ! (PENSION_AGE_DISABILITY in sys.incomes.included),
        ! (ADP_DAILY_LIVING in sys.incomes.included),
        ! (ADP_MOBILITY in sys.incomes.included),
        ! (SEVERE_DISABILITY_ALLOWANCE in sys.incomes.included),
        ! (STATE_PENSION in sys.incomes.included),
        ! (STUDENT_GRANTS in sys.incomes.included),
        ! (STUDENT_LOANS in sys.incomes.included),
        ! (UNIVERSAL_CREDIT in sys.incomes.included),
        ! (WAR_WIDOWS_PENSION in sys.incomes.included),
        ! (WIDOWS_PAYMENT in sys.incomes.included),
        ! (WINTER_FUEL_PAYMENTS in sys.incomes.included),
        ! (WORKING_TAX_CREDIT in sys.incomes.included))
end

function AllLASubsys( uuid :: UUID, sys :: ScottishLegalAidSys )
    AllLASubsys( LASubsys( uuid, sys.civil), LASubsys( uuid, sys.aa ))
end

function AllLASubsys( uuid :: UUID, civil :: OneLegalAidSys, aa :: OneLegalAidSys )
    AllLASubsys( LASubsys( uuid, civil), LASubsys( uuid, aa ))
end

"""
reload from source so we're correctly annualised CAREFUL change load
as default params change
"""
function default_la_subsys( systype :: SystemType )::LASubsys
  subs = if systype == sys_civil
    STBParameters.default_civil_sys( 2023, Float64 )
  else
    STBParameters.default_aa_sys( 2023, Float64 )
  end
  return LASubsys( DEFAULT_UUID, subs )
end

function do_la_run( 
    settings :: Settings, 
    sys1 :: TaxBenefitSystem, 
    sys2 :: TaxBenefitSystem,
    obs  :: Observable )::NamedTuple
    results = Runner.do_one_run( settings, [sys1, sys2], obs )
    obs[]=Progress( settings.uuid, "results-generation", 0, 0, 0, 0 )
    outf = summarise_frames!( results, settings )
    html = all_results_to_html( outf.legalaid, sys2.legalaid ) 
    xlsxfile_civil = export_xlsx( results.legalaid.civil )
    xlsxfile_aa = export_xlsx( results.legalaid.aa )
    xlsxfile = (; aa=xlsxfile_aa, civil=xlsxfile_civil )
    return (; xlsxfile, html )
end

const DEFAULT_SUBSYS = AllLASubsys( DEFAULT_UUID, DEFAULT_CIVIL, DEFAULT_AA )
const DEFAULT_XLSXFILE, DEFAULT_HTML = do_la_run(
    DEFAULT_SETTINGS,
    DEFAULT_PARAMS,
    DEFAULT_PARAMS,
    screen_obs  )
