
# ==== Queue stuff

#
# what's sent to the client: a set for civil or aa
struct OneResponse{T}
    systype :: SystemType
    xlsxfile :: String
    html    :: NamedTuple
    default_params :: LASubsys{T}
    params  :: LASubsys{T}
    message :: String
end

# what;s cached/saved in session: a set of both aa and civil 
struct CompleteResponse{T}
    xlsxfile :: NamedTuple
    html    :: NamedTuple
    default_params :: AllLASubsys{T}
    params  :: AllLASubsys{T}
    message :: String
end

PROGRESS = LRU{UUID,Progress}(maxsize=5)
OUTPUT = LRU{UUID,CompleteResponse}(maxsize=5)

function clearout(uuid::UUID)
    delete!(PROGRESS,uuid)
    delete!(OUTPUT,uuid)
end

const DEFAULT_COMPLETE_RESPONSE = CompleteResponse(
    DEFAULT_XLSXFILE,
    DEFAULT_HTML,
    DEFAULT_SUBSYS,
    DEFAULT_SUBSYS,
    ""
)

function OneResponse( systype :: SystemType, resp :: CompleteResponse ) :: OneResponse
    return if systype == sys_civil
        OneResponse( systype, resp.xlsxfile.civil, resp.html.civil, resp.default_params.civil, resp.params.civil, resp.message )
    else
        OneResponse( systype, resp.xlsxfile.aa, resp.html.aa, resp.default_params.aa, resp.params.aa, resp.message )
    end
end

function get_single_subsys_from_dict( systype :: SystemType )
    allsubsys = OUTPUT[ params.uuid ].params
    if systype == sys_civil 
        return allsubsys.civil
    else 
        return allsubsys.aa
    end
end

function put_single_subsys_to_dict( params  :: LASubsys )
    allresp = get(OUTPUT, params.uuid, nothing )
    if isnothing(allresp)
        allresp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
    end
    if params.systype == sys_civil 
        allresp.params.civil = params
    else 
        allresp.params.aa = params
    end
    OUTPUT[params.uuid] = allresp # not needed??
end

function addcapital( n :: Int ) ::HTTP.Messages.Response
    params = subsys_from_payload()
    @info "before " params.capital_contribution_rates
    addonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    @info "after " params.capital_contribution_rates
    put_single_subsys_to_dict( params )
    default_params=default_la_subsys( params.systype )
    (; default_params, params ) |> json
end

function delcapital( n )::HTTP.Messages.Response
    params = subsys_from_payload()
    delonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    put_single_subsys_to_dict( params )
    default_params=default_la_subsys( params.systype )
    (; default_params, params ) |> json
end

function addincome( n :: Int ) ::HTTP.Messages.Response
    params = subsys_from_payload()
    @info "addincome; before = $(params.income_contribution_rates)"
    @info params.income_contribution_limits
    addonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    @info "addincome; after = $(params.income_contribution_rates)"
    @info params.income_contribution_limits
    put_single_subsys_to_dict( params )
    default_params=default_la_subsys( params.systype )
    (; default_params, params ) |> json
end

function delincome( n )::HTTP.Messages.Response
    params = subsys_from_payload()
    @info "delincome; before = $(params.income_contribution_rates)"
    @info params.income_contribution_limits
    delonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    @info "delincome; after = $(params.income_contribution_rates)"
    @info params.income_contribution_limits
    put_single_subsys_to_dict( params )
    default_params=default_la_subsys( params.systype )
    (; default_params, params ) |> json
end

function dict_obs( settings :: Settings )::Observable
    sobs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(sobs) do p
        completed += p.step
        if p.phase ==  "reached-run-end"
            stacktrace()
            completed = 0
        end
        prog = Progress( settings.uuid, p.phase, p.thread, completed, p.step, p.size )
        # @show "dict_obs: setting PROGRESS[$(settings.uuid)] to $(prog.phase)"
        PROGRESS[settings.uuid] = prog
    end
    return sobs
end 

function load_all()::HTTP.Messages.Response
    resp = nothing
    systype = sys_civil
    try # horrible hack
        params = subsys_from_payload()
        resp = OUTPUT[params.uuid]
        systype = params.systype
    catch
        resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
        resp.params.civil.uuid = uuid4()
        resp.params.aa.uuid = uuid4()
        OUTPUT[resp.params.civil.uuid] = resp
    end
    # @show resp.params
    # @show DEFAULT_COMPLETE_RESPONSE
    return ( response=output_ready, data = OneResponse( systype, resp )) |> json
end

function reset( uuid::UUID, systype :: SystemType )::HTTP.Messages.Response
    resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
    resp.params.civil.uuid = uuid
    resp.params.aa.uuid = uuid
    OUTPUT[uuid] = resp
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json
end

function switch_system( uuid::UUID, systype :: SystemType )::HTTP.Messages.Response
    # new_systype = systype == sys_civil ? sys_aa : sys_civil
    println( "switch_system to $systype")
    resp = OUTPUT[uuid]
    return ( response=output_ready, data = OneResponse( systype, resp )) |> json
end

"""
return output for the 
"""
function get_output(systype::SystemType, uuid :: UUID ) :: NamedTuple
    resp = OUTPUT[uuid]
    return ( response=output_ready, data = OneResponse( systype, resp))
end

function getprogress( uuid :: UUID, systype :: SystemType ) ::HTTP.Messages.Response
    @show "getprogress entered looking for uuid=$uuid" 
    @show "available progess keys are: $(keys(PROGRESS))"
    @show "available output keys are: $(keys(OUTPUT))"
    if( haskey( PROGRESS, uuid ))
        @show "getprogress: key $uuid found "
        progress = PROGRESS[uuid]
        @show "getprogress: progress is $progress" 
        if progress.phase == "reached-run-end" 
            outp = get_output(systype, uuid)
            @assert outp.data.params.uuid == uuid "uuid of returned outp wrong requested=$uuid vs in params=$(outp.data.params.uuid)"
            return outp |> json
        elseif progress.phase == "encountered_error"
            message = OUTPUT[uuid].message
            return message |> ( response=has_error, data=message ) |> json 
        else
            return ( response=has_progress, data=progress, systype=systype ) |> json
        end
    else
        @show "getprogress: no progress found"
        progress = NO_PROGRESS 
        return ( response=no_progress, data=NO_PROGRESS, systype=systype ) |> json
    end
end

"""
Execute a run from the queue.
"""
function do_dict_run( 
    systype::SystemType, 
    uuid :: UUID  )
    allresp = OUTPUT[uuid]
    activesubsys = systype == sys_civil ? allresp.params.civil : allresp.params.aa    
    settings = make_default_settings()
    map_settings_from_subsys!( settings, activesubsys )
    # settings.uuid = UUID(rand(UInt128))
    sobs = dict_obs( settings )
    sobs[]= Progress( settings.uuid, "start-pre", -99, -99, -99, -99 )
    sys2 = deepcopy( DEFAULT_PARAMS )
    sys2.legalaid.civil = map_sys_from_subsys( allresp.params.civil )
    sys2.legalaid.aa = map_sys_from_subsys( allresp.params.aa )
    try 
        res = do_la_run( settings, DEFAULT_PARAMS, sys2, sobs )
        resp = CompleteResponse(
            res.xlsxfile,
            res.html,
            DEFAULT_SUBSYS,
            allresp.params,
            "" )
        OUTPUT[uuid] = resp
        sobs[]= Progress( uuid, "reached-run-end", -99, -99, -99, -99 )
    catch e
        res = deepcopy( DEFAULT_COMPLETE_RESPONSE )
        res.message = "$e"
        OUTPUT[uuid] = resp
        sobs[]= Progress( uuid, "encountered-error", -99, -99, -99, -99 )
    end
end
  
#=
 Implement a job queue. 
 see: https://docs.julialang.org/en/v1/manual/asynchronous-programming/
 for how to set this up.
 !!! NOTE !!! You need __precompile__(false) with Julia 10.x in the 
 module header for this to work.
=# 

#
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 2
#
# This number of submissions
#
const QSIZE = 5

struct SysTypeAndUUID
    systype :: SystemType
    uuid    :: UUID
end

IN_QUEUE = Channel{SysTypeAndUUID}(QSIZE) # 

function clear_queue()
    while isready( IN_QUEUE )
        take!(IN_QUEUE)
    end
end

function submit_job()
    subsys = subsys_from_payload()
    @info "submit_job uuid = $(subsys.uuid)"
    # allsubsys = get_params_from_dict(subsys.uuid)
    allresp = get( OUTPUT, subsys.uuid, nothing )
    if isnothing(allresp)
        allresp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
    end
    if subsys.systype == sys_civil 
        allresp.params.civil = subsys
    else 
        allresp.params.aa = subsys
    end
    OUTPUT[subsys.uuid] = allresp
    sas = SysTypeAndUUID( subsys.systype, subsys.uuid )
    put!( IN_QUEUE, sas )
    qp = Progress( subsys.uuid, "queued", 0, 0, 0, 0 )
    PROGRESS[subsys.uuid] = qp    
    return ( response=has_progress, data=qp ) |> json
 end

function grab_runs_from_queue()
    while true
        onejob = take!( IN_QUEUE )
        # n = $(size(IN_QUEUE))
        println( "taking run from queue" ) # $n")
        try
            do_dict_run( onejob.systype, onejob.uuid ) 
        catch e
            sobs[]= Progress( onejob.uuid, "encountered-error", -99, -99, -99, -99 )
        end
    end
end

#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
  @info "starting handler $i"   
  errormonitor( @async grab_runs_from_queue())
end