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

@testset "1" begin
    @test 1+1 == 2
    @show aasub = LASim.default_la_subsys( sys_aa )
    @show civsub = LASim.default_la_subsys( sys_civil )
    @show civfull = LASim.map_sys_from_subsys( civsub )
    @show civsub = LASim.default_la_subsys( sys_civil )
    @show aafull = LASim.map_sys_from_subsys( aasub )
end 