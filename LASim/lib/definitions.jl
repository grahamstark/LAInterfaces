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
end

function LASubsys( sys :: OneLegalAidSys )
  LASubsys(
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
    net_housing_wealth in sys.included_capital )
end

"""
annualised
"""
function default_la_sys()::LASubsys
  civil = STBParameters.default_civil_sys( 2023, Float64 )
  return LASubsys(civil)
end

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
  return sys
end 

const DEFAULT_PARAMS = make_default_sys()
const DEFAULT_SETTINGS = make_default_settings()t = 0

obs = Observable( Monitor.Progress( UUIDs.uuid4(),"",0,0,0,0))
of = on(obs) do p
    global tot
    println(p)
    tot += p.step
end

# included_capital = WealthSet([net_financial_wealth,net_physical_wealth])


mutable struct LASubsys{T}
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
end

function LASubsys( sys :: OneLegalAidSys )
  LASubsys(
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
    net_housing_wealth in sys.included_capital )
end

"""
annualised
"""
function default_la_sys()::LASubsys
  civil = STBParameters.default_civil_sys( 2023, Float64 )
  return LASubsys(civil)
end

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
  return sys
end 

const DEFAULT_PARAMS = make_default_sys()
const DEFAULT_SETTINGS = make_default_settings()  
const DEFAULT_RUN = do_run( DEFAULT_PARAMS.legalaid.civil )
const DEFAULT_OUTPUT = results_to_html( DEFAULT_RUN )
