module LASim

using Genie
using Genie.Requests
import JSON3
import Genie.Renderer.Json: json
using CSV 
using DataFrames
using Format
using Preferences
using StatsBase 
using Observables
using ArgCheck
using UUIDs
using XLSX 

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .Monitor: Progress
using .RunSettings
using .Results
using .Definitions
using .STBIncomes
using .STBParameters
using .Utils
using .HTMLLibs
using .SingleHouseholdCalculations:do_one_calc

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using .LegalAidRunner


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

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  # sys.legalaid.civil.included_capital = WealthSet([net_financial_wealth])
  return sys
end 

const DEFAULT_PARAMS = make_default_sys()
const DEFAULT_SETTINGS = make_default_settings()

"""
Defined here to aviod nasty cross-dependency.
Compile the list of hh `examples` into one massive stringfull of HTML.
"""
function make_examples( 
  examples :: AbstractVector;
  la2 :: OneLegalAidSys  )::String
  sys2 = deepcopy(DEFAULT_PARAMS)
  if la2.systype == sys_civil
    sys2.legalaid.civil = deepcopy(la2)
  else
    sys2.legalaid.aa = deepcopy(la2)
  end
  print = PrintControls()
  s = ""
  for oi in examples 
    hh = FRSHouseholdGetter.get_household( oi )
    pre = do_one_calc( hh, DEFAULT_PARAMS )
    post = do_one_calc( hh, sys2 )
    s *= "<h2>Household Results #$(oi.id) - $(oi.data_year)</h2>"
    s *= HTMLLibs.format( hh, pre, post; settings=DEFAULT_SETTINGS, print=print )
    s *= "<hr/>"
  end
  return s
end

include( "../lib/exporter.jl")
include("../lib/html.jl")
include("../lib/definitions.jl")
include("../lib/handlers.jl")

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

#=
to start from repl: 

using Genie
using Revise
Genie.loadapp()
up()
=#

end
