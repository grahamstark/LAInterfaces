
module LASim
__precompile__(false)
using Genie
using Genie.Requests
import Genie.Renderer.Json: json
using GenieSession 
using GenieSessionFileSession

import JSON3
using ArgCheck
using CSV 
using DataFrames
using Format
using Logging, LoggingExtras
using LRUCache
using Observables
using Preferences
using StatsBase 
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
using .STBOutput: summarise_frames!
using .SingleHouseholdCalculations: do_one_calc

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
# using .LegalAidRunner

@enum Responses output_ready has_progress load_params bad_request

const DEFAULT_UUID = UUID("c2ae9c83-d24a-431c-b04f-74662d2ba07e")
const HOME_DIR = joinpath(dirname(pathof( LASim )),".." )

logger = FileLogger( joinpath( HOME_DIR, "log", "lasim_log.txt"))
global_logger(logger)
LogLevel( Logging.Debug )

function make_default_settings() :: Settings
  settings = Settings()
  settings.export_full_results = true
  settings.do_legal_aid = true
  settings.do_marginal_rates = false
  settings.requested_threads = 4
  settings.wealth_method = other_method_1
  settings.num_households, settings.num_people, nhh2 = 
      FRSHouseholdGetter.initialise( settings; reset=false ) # force Scottish dataset 
  # ExampleHouseholdGetter.initialise( settings ) # force a reload for reasons I don't quite understand.
  return settings
end

function make_default_sys()
  sys = STBParameters.get_default_system_for_fin_year( 2023, scotland=true )
  return sys
end 

function make_screen_obs()::Observable
  obs = Observable( Progress( DEFAULT_UUID, "",0,0,0,0))
  completed = 0
  of = on(obs) do p
      if p.phase == "do-one-run-end"
      completed = 0
      end
      completed += p.step
      @info "monitor completed=$completed p = $(p)"
  end
  return obs
end

screen_obs = make_screen_obs()

const DEFAULT_PARAMS = make_default_sys()
const DEFAULT_SETTINGS = make_default_settings() 

"""
Defined here to aviod nasty cross-dependency.
Compile the list of hh `examples` into one massive stringfull of HTML.
"""
function make_examples( 
  examples :: AbstractVector;
  la2      :: OneLegalAidSys  )::String
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
include( "../lib/html.jl")
include( "../lib/definitions.jl")
include( "../lib/handlers.jl")
include( "../lib/queues_and_sessions.jl")

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

end # module
