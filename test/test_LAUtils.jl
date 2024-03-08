using Test
using Main.LAUtils
using ScottishTaxBenefitModel
using .LegalAidOutput

@testset "LAUtils Test" begin

    settings = make_default_settings()
    settings.run_name = "LAUtils Test"
    odp = LAUtils.BASE_SYS.legalaid.civil.income_other_dependants_allowance 
    laout = LAUtils.run( settings, odp )
    println( format_crosstab( laout.civil.crosstab_pers[1]["no_problem-prediction"] )) 
    LegalAidOutput.dump_tables( laout, settings, 2 )
    LegalAidOutput.dump_frames( laout, settings, 2 )
    println(LAUtils.BASE_SYS)
end