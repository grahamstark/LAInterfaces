#

function make_default_settings() :: Settings
    settings = Settings()
    settings.export_full_results = true
    settings.do_legal_aid = true
    settings.do_marginal_rates = false
    settings.requested_threads = 4
    settings.num_households, settings.num_people, nhh2 = 
        FRSHouseholdGetter.initialise( settings; reset=true ) # force Scottish dataset 
    # ExampleHouseholdGetter.initialise( settings ) # force a reload for reasons I don't quite understand.
    return settings
end

tot = 0

obs = Observable( Monitor.Progress( UUIDs.uuid4(),"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
end

# included_capital = WealthSet([net_financial_wealth,net_physical_wealth])


mutable struct LASubsys{T}
    systype :: SystemType    
    income_living_allowance :: T       
    income_partners_allowance   :: T        
    income_other_dependants_allowance :: T  
    income_child_allowance   :: T   
    INCOME_SUPPORT_passported :: Bool
    NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_passported :: Bool
    NON_CONTRIB_JOBSEEKERS_ALLOWANCE_passported  :: Bool
    UNIVERSAL_CREDIT_passported  :: Bool 
    net_financial_wealth :: Bool
    net_physical_wealth :: Bool
    net_housing_wealth :: Bool    
    income_contribution_rates :: Vector{T}
    income_contribution_limits :: Vector{T}  
    capital_contribution_rates :: Vector{T}
    capital_contribution_limits :: Vector{T}  

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

end
  
function LASubsys( sys :: OneLegalAidSys )
    LASubsys(
      sys.systype,
      sys.income_living_allowance,
      sys.income_partners_allowance,        
      sys.income_other_dependants_allowance,
      sys.income_child_allowance,
      INCOME_SUPPORT in sys.passported_benefits,
      NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE in sys.passported_benefits,
      NON_CONTRIB_JOBSEEKERS_ALLOWANCE in sys.passported_benefits, 
      UNIVERSAL_CREDIT in sys.passported_benefits,
      net_financial_wealth in sys.included_capital,
      net_physical_wealth in sys.included_capital,
      net_housing_wealth in sys.included_capital,
      sys.income_contribution_rates,
      sys.income_contribution_limits,
      sys.capital_contribution_rates,
      sys.capital_contribution_limits,

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
      sys.expenses.repayments.max )
      
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
  return LASubsys(subs)
end

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  # sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
  return sys
end 

const DEFAULT_PARAMS = make_default_sys()
const DEFAULT_SETTINGS = make_default_settings()

tot = 0
obs = Observable( Monitor.Progress( UUIDs.uuid4(),"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
end

# included_capital = WealthSet([net_financial_wealth,net_physical_wealth])

"""
FIXME: better place for this.
"""
function do_run( la2 :: OneLegalAidSys; systype :: SystemType  )
    global tot
    tot = 0
    sys2 = deepcopy(DEFAULT_PARAMS)
    if systype == sys_civil 
        sys2.legalaid.civil = deepcopy(la2)
    else
        sys2.legalaid.aa = deepcopy(la2)
    end
    allout = LegalAidRunner.do_one_run( DEFAULT_SETTINGS, [DEFAULT_PARAMS,sys2], obs )
    return allout
end

function do_default_run()
    global tot
    allout = LegalAidRunner.do_one_run( 
        DEFAULT_SETTINGS, 
        [DEFAULT_PARAMS,DEFAULT_PARAMS], obs )
    return allout
end

const DEFAULT_RUN = do_default_run()
const DEFAULT_OUTPUT = results_to_html( DEFAULT_RUN )

function get_default_output( systype :: SystemType )
    return systype == sys_civil ? DEFAULT_OUTPUT.civil : DEFAULT_OUTPUT.aa 
end
