#

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
    println( "sys.income_contribution_rates was: $(sys.income_contribution_rates)")
    println( "sys.income_contribution_limit was: $(sys.income_contribution_limits)")
    sys.income_contribution_rates = pars.income_contribution_rates ./100
    println( "sys.income_contribution_rates now: $(sys.income_contribution_rates)")
    sys.income_contribution_limits = pars.income_contribution_limits ./ WEEKS_PER_YEAR
    println( "sys.income_contribution_limit now: $(sys.income_contribution_limits)")
    println( "sys.capital_contribution_rates was: $(sys.capital_contribution_rates)")
    sys.capital_contribution_rates = pars.capital_contribution_rates  ./100
    println( "sys.capital_contribution_rates now: $(sys.capital_contribution_rates)")
    println( "sys.capital_contribution_limits was: $(sys.capital_contribution_limits)")
    sys.capital_contribution_limits = pars.capital_contribution_limits
    println( "sys.capital_contribution_limits now: $(sys.capital_contribution_limits)")
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
    params = JSON3.read( rawpayload(), LASubsys{Float64})
    @info "addincome; before = $(params.income_contribution_rates)"
    addonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    @info "addincome; after = $(params.income_contribution_rates)"
    defaults=default_la_sys()
    (; params, defaults ) |> json
end

function delincome( n )
    params = JSON3.read( rawpayload(), LASubsys{Float64})
    println( "delincome; before = $(params.income_contribution_rates)" )
    delonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    println( "delincome; after = $(params.income_contribution_rates)" )
    defaults=default_la_sys()
    (; params, defaults ) |> json
end

function addcapital( n :: Int ) 
    params = JSON3.read( rawpayload(), LASubsys{Float64})
    addonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    defaults=default_la_sys()
    (; params, defaults ) |> json
end

function delcapital( n )
    params = JSON3.read( rawpayload(), LASubsys{Float64})
    delonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    defaults=default_la_sys()
    (; params, defaults ) |> json
end


  
  