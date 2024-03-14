# get around weird bug similar to: https://github.com/GenieFramework/Genie.jl/issues/433
__precompile__(false)


module LASim

using Genie
using Genie.Requests
import JSON3
import Genie.Renderer.Json: json
using CSV 
using DataFrames
using Format
using StatsBase 
using Observables
using ArgCheck
using UUIDs

using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .GeneralTaxComponents: WEEKS_PER_YEAR
using .Monitor: Progress
using .RunSettings
using .Results
using .Definitions
using .STBIncomes
using .STBParameters: 
  TaxBenefitSystem, 
  get_default_system_for_fin_year, 
  OneLegalAidSys, 
  ScottishLegalAidSys, 
  weeklyise!

using .Utils

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using .LegalAidRunner

include("../lib/html.jl")
include("../lib/definitions.jl")
include("../lib/handlers.jl")

const up = Genie.up
export up

function main()
  Genie.genie(; context = @__MODULE__)
end

end
