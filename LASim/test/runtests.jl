using Test

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

using LASim
using ScottishTaxBenefitModel
using .FRSHouseholdGetter
using .Monitor: Progress
using .RunSettings
using .Results
using .Definitions
using .STBIncomes
using .STBParameters
using .Utils

using .LegalAidCalculations: calc_legal_aid!
using .LegalAidData
using .LegalAidOutput
using .LegalAidRunner

include( "latests.jl")