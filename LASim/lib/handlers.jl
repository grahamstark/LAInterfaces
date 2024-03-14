#


function do_run( la2 :: OneLegalAidSys; iscivil=true )
    global tot
    tot = 0
    sys2 = deepcopy(DEFAULT_PARAMS)
    if iscivil
      sys2.legalaid.civil = deepcopy(la2)
      # weeklyise!( sys2.legalaid.civil )
    else
      sys2.legalaid.aa = la2
    end  
    allout = LegalAidRunner.do_one_run( DEFAULT_SETTINGS, [DEFAULT_PARAMS,sys2], obs )
    return allout
end


function spop!( s :: Set, thing )
    if thing in s
      t = pop!( s, thing )
    end
end
  
function sysfrompayload( payload ) :: Tuple
    pars = JSON3.read( payload, LASubsys{Float64})
    @show pars
    
    # make this swappable to aa
    sys = deepcopy( DEFAULT_PARAMS.legalaid.civil )
    sys.income_living_allowance           = pars.income_living_allowance/WEEKS_PER_YEAR
    sys.income_partners_allowance         = pars.income_partners_allowance/WEEKS_PER_YEAR
    sys.income_other_dependants_allowance = pars.income_other_dependants_allowance/WEEKS_PER_YEAR
    sys.income_child_allowance            = pars.income_child_allowance/WEEKS_PER_YEAR
    if pars.INCOME_SUPPORT_passported 
      push!( sys.passported_benefits, INCOME_SUPPORT )
    else
      try
        pop!(sys.passported_benefits,INCOME_SUPPORT)
      catch
      end
    end
    if pars.NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE_passported 
      push!( sys.passported_benefits, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE )
    else
      spop!(sys.passported_benefits, NON_CONTRIB_EMPLOYMENT_AND_SUPPORT_ALLOWANCE)
    end
    if pars.NON_CONTRIB_JOBSEEKERS_ALLOWANCE_passported
      push!( sys.passported_benefits, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    else
      spop!(sys.passported_benefits, NON_CONTRIB_JOBSEEKERS_ALLOWANCE )
    end
    if pars.UNIVERSAL_CREDIT_passported
      push!( sys.passported_benefits, UNIVERSAL_CREDIT )
    else
      spop!(sys.passported_benefits, UNIVERSAL_CREDIT )
    end
    if pars.net_financial_wealth
      push!( sys.included_capital, net_financial_wealth ) 
    else
      spop!( sys.included_capital, net_financial_wealth )
    end
    if pars.net_physical_wealth
      push!( sys.included_capital, net_physical_wealth ) 
    else
      spop!( sys.included_capital, net_physical_wealth )
    end
    if pars.net_housing_wealth
      push!( sys.included_capital, net_housing_wealth ) 
    else
      spop!( sys.included_capital, net_housing_wealth )
    end
    return sys, pars
end
  
function reset()
    defaults = default_la_sys()
    @info defaults
    (; output=DEFAULT_OUTPUT, 
       params = defaults,
       defaults = defaults ) |> json
end
  
function run()
    lasys, params = sysfrompayload( rawpayload()) 
    lares = do_run( lasys )
    output = results_to_html( lares )
    # params = lasys
    defaults = default_la_sys() #DEFAULT_PARAMS.legalaid.civil
    (; output, params, defaults ) |> json
end
  
  