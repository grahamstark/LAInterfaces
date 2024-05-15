#

function spop!( s :: AbstractSet, thing )
    if thing in s
      t = pop!( s, thing )
    end
end

function subsys_from_payload()
  return JSON3.read( rawpayload(), LASubsys{Float64})
end

function map_settings_from_subsys!( subsys :: LASubsys )
  if DEFAULT_SETTINGS.wealth_method != subsys.wealth_method
    DEFAULT_SETTINGS.wealth_method = subsys.wealth_method
    if subsys.reset_all_if_changed
      global DEFAULT_RUN
      global DEFAULT_OUTPUT 
      DEFAULT_RUN = do_default_run()
      DEFAULT_OUTPUT = all_results_to_html( DEFAULT_RUN, DEFAULT_PARAMS.legalaid )
    end
  end
end
  
function map_sys_from_subsys( subsys :: LASubsys )::OneLegalAidSys
    # make this swappable to aa
    fullsys = if subsys.systype == sys_civil 
      deepcopy( DEFAULT_PARAMS.legalaid.civil )
    else
      deepcopy( DEFAULT_PARAMS.legalaid.aa )
    end
    fullsys.income_living_allowance           = subsys.income_living_allowance
    fullsys.income_partners_allowance         = subsys.income_partners_allowance
    fullsys.income_other_dependants_allowance = subsys.income_other_dependants_allowance
    fullsys.income_child_allowance            = subsys.income_child_allowance
    if subsys.INCOME_SUPPORT_passported 
      push!( fullsys.passported_benefits, INCOME_SUPPORT )
    else
      try
        pop!(fullsys.passported_benefits,INCOME_SUPPORT)
      catch
      end
    end
    if subsys.NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_passported 
      push!( fullsys.passported_benefits, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
    else
      spop!( fullsys.passported_benefits, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE)
    end
    if subsys.NON_CONTRIB_JOBSEEKERS_ALLOWANCE_passported
      push!( fullsys.passported_benefits, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    else
      spop!( fullsys.passported_benefits, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    end
    if subsys.UNIVERSAL_CREDIT_passported
      push!( fullsys.passported_benefits, UNIVERSAL_CREDIT )
    else
      spop!( fullsys.passported_benefits, UNIVERSAL_CREDIT )
    end
    if subsys.net_financial_wealth
      push!( fullsys.included_capital, net_financial_wealth ) 
    else
      spop!( fullsys.included_capital, net_financial_wealth )
    end
    if subsys.net_physical_wealth
      push!( fullsys.included_capital, net_physical_wealth ) 
    else
      spop!( fullsys.included_capital, net_physical_wealth )
    end
    if subsys.net_housing_wealth
      push!( fullsys.included_capital, net_housing_wealth ) 
    else
      spop!( fullsys.included_capital, net_housing_wealth )
    end
    println( "sys.income_contribution_rates was: $(fullsys.income_contribution_rates)")
    println( "sys.income_contribution_limit was: $(fullsys.income_contribution_limits)")
    fullsys.income_contribution_rates = copy(subsys.income_contribution_rates)
    println( "sys.income_contribution_rates now: $(fullsys.income_contribution_rates)")
    fullsys.income_contribution_limits = copy(subsys.income_contribution_limits)
    println( "sys.income_contribution_limit now: $(fullsys.income_contribution_limits)")
    println( "sys.capital_contribution_rates was: $(fullsys.capital_contribution_rates)")
    fullsys.capital_contribution_rates = copy(subsys.capital_contribution_rates)
    println( "sys.capital_contribution_rates now: $(fullsys.capital_contribution_rates)")
    println( "sys.capital_contribution_limits was: $(fullsys.capital_contribution_limits)")
    fullsys.capital_contribution_limits = copy(subsys.capital_contribution_limits)
    println( "sys.capital_contribution_limits now: $(fullsys.capital_contribution_limits)")

    fullsys.expenses.housing = Expense( subsys.housing_is_flat, subsys.housing_v, subsys.housing_max )
    fullsys.expenses.childcare = Expense( subsys.childcare_is_flat, subsys.childcare_v, subsys.childcare_max )
    fullsys.expenses.work_expenses = Expense( subsys.work_expenses_is_flat, subsys.work_expenses_v, subsys.work_expenses_max )
    fullsys.expenses.maintenance = Expense( subsys.maintenance_is_flat, subsys.maintenance_v, subsys.maintenance_max )
    fullsys.expenses.repayments = Expense( subsys.repayments_is_flat, subsys.repayments_v, subsys.repayments_max )
    
    fullsys.premia.family = subsys.prem_family
    fullsys.premia.family_lone_parent  = subsys.prem_family_lone_parent
    fullsys.premia.disabled_child = subsys.prem_disabled_child
    fullsys.premia.carer_single = subsys.prem_carer_single
    fullsys.premia.carer_couple = subsys.prem_carer_couple
    fullsys.premia.disability_single = subsys.prem_disability_single
    fullsys.premia.disability_couple = subsys.prem_disability_couple
    fullsys.uc_limit = subsys.uc_limit
    fullsys.uc_limit_type = subsys.uc_limit_type
    fullsys.uc_use_earnings = subsys.uc_use_earnings
    println( "before ben pushes")
    @debug subsys
    @debug fullsys.incomes.included
    if subsys.FRIENDLY_SOCIETY_BENEFITS_disregarded 
      spop!(fullsys.incomes.included, FRIENDLY_SOCIETY_BENEFITS )
    else
        push!( fullsys.incomes.included, FRIENDLY_SOCIETY_BENEFITS )
    end
    if subsys.PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING_disregarded 
        spop!(fullsys.incomes.included, PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING )
    else
        push!( fullsys.incomes.included, PERSONAL_INDEPENDENCE_PAYMENT_DAILY_LIVING )
    end
    if subsys.BEREAVEMENT_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, BEREAVEMENT_ALLOWANCE )
    else
        push!( fullsys.incomes.included, BEREAVEMENT_ALLOWANCE )
    end
    if subsys.ATTENDANCE_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, ATTENDANCE_ALLOWANCE )
    else
        push!( fullsys.incomes.included, ATTENDANCE_ALLOWANCE )
    end
    if subsys.PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY_disregarded 
        spop!(fullsys.incomes.included, PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY )
    else
        push!( fullsys.incomes.included, PERSONAL_INDEPENDENCE_PAYMENT_MOBILITY )
    end
    if subsys.WIDOWS_PAYMENT_disregarded 
        spop!(fullsys.incomes.included, WIDOWS_PAYMENT )
    else
        push!( fullsys.incomes.included, WIDOWS_PAYMENT )
    end
    if subsys.DLA_MOBILITY_disregarded 
        spop!(fullsys.incomes.included, DLA_MOBILITY )
    else
        push!( fullsys.incomes.included, DLA_MOBILITY )
    end
    if subsys.MATERNITY_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, MATERNITY_ALLOWANCE )
    else
        push!( fullsys.incomes.included, MATERNITY_ALLOWANCE )
    end
    if subsys.WINTER_FUEL_PAYMENTS_disregarded 
        spop!(fullsys.incomes.included, WINTER_FUEL_PAYMENTS )
    else
        push!( fullsys.incomes.included, WINTER_FUEL_PAYMENTS )
    end
    if subsys.SCOTTISH_CARERS_SUPPLEMENT_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_CARERS_SUPPLEMENT )
    else
        push!( fullsys.incomes.included, SCOTTISH_CARERS_SUPPLEMENT )
    end
    if subsys.SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY )
    else
        push!( fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_MOBILITY )
    end
    if subsys.DISCRESIONARY_HOUSING_PAYMENT_disregarded 
        spop!(fullsys.incomes.included, DISCRESIONARY_HOUSING_PAYMENT )
    else
        push!( fullsys.incomes.included, DISCRESIONARY_HOUSING_PAYMENT )
    end
    if subsys.SCOTTISH_CHILD_PAYMENT_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_CHILD_PAYMENT )
    else
        push!( fullsys.incomes.included, SCOTTISH_CHILD_PAYMENT )
    end
    if subsys.INCAPACITY_BENEFIT_disregarded 
        spop!(fullsys.incomes.included, INCAPACITY_BENEFIT )
    else
        push!( fullsys.incomes.included, INCAPACITY_BENEFIT )
    end
    if subsys.SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY )
    else
        push!( fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_MOBILITY )
    end
    if subsys.WAR_WIDOWS_PENSION_disregarded 
        spop!(fullsys.incomes.included, WAR_WIDOWS_PENSION )
    else
        push!( fullsys.incomes.included, WAR_WIDOWS_PENSION )
    end
    if subsys.FOSTER_CARE_PAYMENTS_disregarded 
        spop!(fullsys.incomes.included, FOSTER_CARE_PAYMENTS )
    else
        push!( fullsys.incomes.included, FOSTER_CARE_PAYMENTS )
    end
    if subsys.BASIC_INCOME_disregarded 
        spop!(fullsys.incomes.included, BASIC_INCOME )
    else
        push!( fullsys.incomes.included, BASIC_INCOME )
    end
    if subsys.WORKING_TAX_CREDIT_disregarded 
        spop!(fullsys.incomes.included, WORKING_TAX_CREDIT )
    else
        push!( fullsys.incomes.included, WORKING_TAX_CREDIT )
    end
    if subsys.FREE_SCHOOL_MEALS_disregarded 
        spop!(fullsys.incomes.included, FREE_SCHOOL_MEALS )
    else
        push!( fullsys.incomes.included, FREE_SCHOOL_MEALS )
    end
    if subsys.DLA_SELF_CARE_disregarded 
        spop!(fullsys.incomes.included, DLA_SELF_CARE )
    else
        push!( fullsys.incomes.included, DLA_SELF_CARE )
    end
    if subsys.GOVERNMENT_TRAINING_ALLOWANCES_disregarded 
        spop!(fullsys.incomes.included, GOVERNMENT_TRAINING_ALLOWANCES )
    else
        push!( fullsys.incomes.included, GOVERNMENT_TRAINING_ALLOWANCES )
    end
    if subsys.UNIVERSAL_CREDIT_disregarded 
        spop!(fullsys.incomes.included, UNIVERSAL_CREDIT )
    else
        push!( fullsys.incomes.included, UNIVERSAL_CREDIT )
    end
    if subsys.STUDENT_LOANS_disregarded 
        spop!(fullsys.incomes.included, STUDENT_LOANS )
    else
        push!( fullsys.incomes.included, STUDENT_LOANS )
    end
    if subsys.CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
    else
        push!( fullsys.incomes.included, CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
    end
    if subsys.NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
    else
        push!( fullsys.incomes.included, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
    end
    if subsys.CARERS_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, CARERS_ALLOWANCE )
    else
        push!( fullsys.incomes.included, CARERS_ALLOWANCE )
    end
    if subsys.INCOME_SUPPORT_disregarded 
        spop!(fullsys.incomes.included, INCOME_SUPPORT )
    else
        push!( fullsys.incomes.included, INCOME_SUPPORT )
    end
    if subsys.HOUSING_BENEFIT_disregarded 
        spop!(fullsys.incomes.included, HOUSING_BENEFIT )
    else
        push!( fullsys.incomes.included, HOUSING_BENEFIT )
    end
    if subsys.COUNCIL_TAX_BENEFIT_disregarded 
        spop!(fullsys.incomes.included, COUNCIL_TAX_BENEFIT )
    else
        push!( fullsys.incomes.included, COUNCIL_TAX_BENEFIT )
    end
    if subsys.CHILD_BENEFIT_disregarded 
        spop!(fullsys.incomes.included, CHILD_BENEFIT )
    else
        push!( fullsys.incomes.included, CHILD_BENEFIT )
    end
    if subsys.STATE_PENSION_disregarded 
        spop!(fullsys.incomes.included, STATE_PENSION )
    else
        push!( fullsys.incomes.included, STATE_PENSION )
    end
    if subsys.SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE )
    else
        push!( fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_OLDER_PEOPLE )
    end
    if subsys.CONTRIB_JOBSEEKERS_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, CONTRIB_JOBSEEKERS_ALLOWANCE )
    else
        push!( fullsys.incomes.included, CONTRIB_JOBSEEKERS_ALLOWANCE )
    end
    if subsys.NON_CONTRIB_JOBSEEKERS_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    else
        push!( fullsys.incomes.included, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    end
    if subsys.SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING )
    else
        push!( fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_CHILDREN_DAILY_LIVING )
    end
    if subsys.SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING_disregarded 
        spop!(fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING )
    else
        push!( fullsys.incomes.included, SCOTTISH_DISABILITY_ASSISTANCE_WORKING_AGE_DAILY_LIVING )
    end
    if subsys.ANY_OTHER_NI_OR_STATE_BENEFIT_disregarded 
        spop!(fullsys.incomes.included, ANY_OTHER_NI_OR_STATE_BENEFIT )
    else
        push!( fullsys.incomes.included, ANY_OTHER_NI_OR_STATE_BENEFIT )
    end
    if subsys.MATERNITY_GRANT_disregarded 
        spop!(fullsys.incomes.included, MATERNITY_GRANT )
    else
        push!( fullsys.incomes.included, MATERNITY_GRANT )
    end
    if subsys.FUNERAL_GRANT_disregarded 
        spop!(fullsys.incomes.included, FUNERAL_GRANT )
    else
        push!( fullsys.incomes.included, FUNERAL_GRANT )
    end
    if subsys.PENSION_CREDIT_disregarded 
        spop!(fullsys.incomes.included, PENSION_CREDIT )
    else
        push!( fullsys.incomes.included, PENSION_CREDIT )
    end
    if subsys.SAVINGS_CREDIT_disregarded 
        spop!(fullsys.incomes.included, SAVINGS_CREDIT )
    else
        push!( fullsys.incomes.included, SAVINGS_CREDIT )
    end
    if subsys.SEVERE_DISABILITY_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, SEVERE_DISABILITY_ALLOWANCE )
    else
        push!( fullsys.incomes.included, SEVERE_DISABILITY_ALLOWANCE )
    end
    if subsys.INDUSTRIAL_INJURY_BENEFIT_disregarded 
        spop!(fullsys.incomes.included, INDUSTRIAL_INJURY_BENEFIT )
    else
        push!( fullsys.incomes.included, INDUSTRIAL_INJURY_BENEFIT )
    end
    if subsys.ARMED_FORCES_COMPENSATION_SCHEME_disregarded 
        spop!(fullsys.incomes.included, ARMED_FORCES_COMPENSATION_SCHEME )
    else
        push!( fullsys.incomes.included, ARMED_FORCES_COMPENSATION_SCHEME )
    end
    if subsys.GUARDIANS_ALLOWANCE_disregarded 
        spop!(fullsys.incomes.included, GUARDIANS_ALLOWANCE )
    else
        push!( fullsys.incomes.included, GUARDIANS_ALLOWANCE )
    end
    if subsys.STUDENT_GRANTS_disregarded 
        spop!(fullsys.incomes.included, STUDENT_GRANTS )
    else
        push!( fullsys.incomes.included, STUDENT_GRANTS )
    end
    if subsys.CHILD_TAX_CREDIT_disregarded 
        spop!(fullsys.incomes.included, CHILD_TAX_CREDIT )
    else
        push!( fullsys.incomes.included, CHILD_TAX_CREDIT )
    end
    if subsys.EDUCATION_ALLOWANCES_disregarded 
        spop!(fullsys.incomes.included, EDUCATION_ALLOWANCES )
    else
        push!( fullsys.incomes.included, EDUCATION_ALLOWANCES )
    end
    if subsys.OTHER_BENEFITS_disregarded 
        spop!(fullsys.incomes.included, OTHER_BENEFITS )
    else
        push!( fullsys.incomes.included, OTHER_BENEFITS )
    end
    println( "after ben pushes")
    @debug fullsys.incomes.included
    
    weeklyise!( fullsys )
    @debug fullsys
    @debug fullsys.premia
    return fullsys
end
  
function reset()
    # don't try to load all of it since it might be unset, just sys type
    rp = jsonpayload()
    @debug rp
    systype = rp["systype"] == "sys_aa" ? sys_aa : sys_civil
    # subsys = subsys_from_payload()
    defaults = default_la_subsys( systype )
    output=get_default_output( systype )
    xlsxfile = export_xlsx( get_default_results( systype ) ) # FIXME no need to repeat this here.
    @info defaults
    (; output=output, 
       params = defaults,
       defaults = defaults,
       xlsxfile ) |> json
end

function switch_system()
    reset()
end
  
function run()
    subsys = subsys_from_payload()
    fullsys = map_sys_from_subsys( subsys ) 
    map_settings_from_subsys!( subsys )

    lares, sys2 = do_run( fullsys; systype=subsys.systype )
    alloutput = all_results_to_html( lares, sys2.legalaid )
    output = nothing
    xlsxfile = nothing
    if subsys.systype == sys_civil 
      output = alloutput.civil
      xlsxfile = export_xlsx( lares.civil )
    else
      output = alloutput.aa
      xlsxfile = export_xlsx( lares.aa )
    end
    # params = lasys
    defaults = default_la_subsys( subsys.systype )
    (; output, params=subsys, defaults, xlsxfile ) |> json
end

function delonerb!( 
    rates::AbstractVector, 
    bands::AbstractVector, 
    pos::Integer )
    sz = size(rates)[1]
    sb = size(bands)[1]
    @assert sb in (sz-1):sz
    if pos > sz
        return
    end
    deleteat!( rates, pos )
    # top case where there's no explicit top band
    if sz > sb && pos == sz
        deleteat!( bands, pos-1)
    else
        deleteat!( bands, pos )
    end
end

function addonerb!( 
    rates::AbstractVector{T}, 
    bands::AbstractVector{T}, 
    pos::Integer, 
    val :: T = zero(T) ) where T
    sz = size(rates)[1]
    sb = size(bands)[1]
    @assert sb in (sz-1):sz
    if pos in 1:sz
        insert!( rates, pos, val )
        if pos <= sb
            insert!( bands, pos, val )
        else
            push!(  bands, val )
        end
    else
        push!( bands, val )
        push!( rates, val )
    end
end

function addincome( n :: Int ) 
    params = subsys_from_payload()
    @info "addincome; before = $(params.income_contribution_rates)"
    addonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    @info "addincome; after = $(params.income_contribution_rates)"
    defaults=default_la_subsys( params.systype )
    (; params, defaults ) |> json
end

function delincome( n )
    params = subsys_from_payload()
    println( "delincome; before = $(params.income_contribution_rates)" )
    delonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    println( "delincome; after = $(params.income_contribution_rates)" )
    defaults=default_la_subsys( params.systype )
    (; params, defaults ) |> json
end

function addcapital( n :: Int ) 
    params = subsys_from_payload()
    addonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    defaults=default_la_subsys( params.systype )
    (; params, defaults ) |> json
end

function delcapital( n )
    params = subsys_from_payload()
    delonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    defaults=default_la_subsys( params.systype )
    (; params, defaults ) |> json
end