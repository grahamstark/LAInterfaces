
# ==== Queue stuff

#
# what's sent to the client: a set for civil or aa
struct OneResponse{T}
    systype :: SystemType
    xlsxfile :: String
    html    :: NamedTuple
    default_params :: LASubsys{T}
    params  :: LASubsys{T}
end

# what;s cached/saved in session: a set of both aa and civil 
struct CompleteResponse{T}
    xlsxfile :: NamedTuple
    html    :: NamedTuple
    default_params :: AllLASubsys{T}
    params  :: AllLASubsys{T}
end

PROGRESS = Dict{UUID,Progress}()

const DEFAULT_COMPLETE_RESPONSE = CompleteResponse(
    DEFAULT_XLSXFILE,
    DEFAULT_HTML,
    DEFAULT_SUBSYS,
    DEFAULT_SUBSYS
)

function OneResponse( systype :: SystemType, resp :: CompleteResponse ) :: OneResponse
    return if systype == sys_civil
        OneResponse( systype, resp.xlsxfile.civil, resp.html.civil, resp.default_params.civil, resp.params.civil )
    else
        OneResponse( systype, resp.xlsxfile.aa, resp.html.aa, resp.default_params.aa, resp.params.aa )
    end
end

function to_session( session, res :: CompleteResponse )
    # GenieSession.set!( session, :systype, res.systype )
    GenieSession.set!( session, :xlsxfile, res.xlsxfile )
    GenieSession.set!( session, :html, res.html )
    GenieSession.set!( session, :allsubsys, res.params )
end

function from_session(session)::CompleteResponse 
    if( GenieSession.isset( session, :html ))
        return CompleteResponse(
            GenieSession.get( session, :xlsxfile ),
            GenieSession.get( session, :html),
            DEFAULT_SUBSYS,
            GenieSession.get( session, :allsubsys ))
    else
        resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
        to_session( session, resp )
        return resp
    end
end

function get_single_subsys_from_session( systype :: SystemType, session::GenieSession.Session):: LASubsys
    allsubsys = get_params_from_session( session )
    # params = subsys_from_payload()
    if systype == sys_civil 
        params = allsubsys.civil
    else 
        params = allsubsys.aa
    end
end

function put_single_subsys_to_session( 
    systype :: SystemType, 
    session ::GenieSession.Session,
    params  :: LASubsys )
    allsubsys = get_params_from_session( session )
    if systype == sys_civil 
        allsubsys.civil = params
    else 
        allsubsys.aa = params
    end
    GenieSession.set!( session, :allsubsys, allsubsys )    
end

function addcapital( n :: Int ) 
    session = GenieSession.session()
    systype = systype_from_session(session)
    params = get_single_subsys_from_session( systype, session )
    @info "before " params.capital_contribution_rates
    addonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    @info "after " params.capital_contribution_rates
    put_single_subsys_to_session( systype, session, params )
    default_params=default_la_subsys( systype )
    (; default_params, params ) |> json
end

function delcapital( n )
    session = GenieSession.session()
    systype = systype_from_session(session)
    params = get_single_subsys_from_session( systype, session )
    delonerb!( 
        params.capital_contribution_rates, 
        params.capital_contribution_limits,
        n )
    put_single_subsys_to_session( systype, session, params )
    default_params=default_la_subsys( systype )
    (; default_params, params ) |> json
end

function addincome( n :: Int ) 
    session = GenieSession.session()
    systype = systype_from_session(session)
    params = get_single_subsys_from_session( systype, session )
    @info "addincome; before = $(params.income_contribution_rates)"
    addonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    @info "addincome; after = $(params.income_contribution_rates)"
    put_single_subsys_to_session( systype, session, params )
    default_params=default_la_subsys( params.systype )
    (; default_params, params ) |> json
end

function delincome( n )
    session = GenieSession.session()
    systype = systype_from_session(session)
    params = get_single_subsys_from_session( systype, session )
    println( "delincome; before = $(params.income_contribution_rates)" )
    delonerb!( 
        params.income_contribution_rates, 
        params.income_contribution_limits,
        n )
    put_single_subsys_to_session( systype, session, params )
    default_params=default_la_subsys( systype )
    (; default_params, params ) |> json
end

# const CACHED_RESULTS = LRU{AllLASubsys,CompleteResponse}(maxsize=25)

function systype_from_session( session ::GenieSession.Session )
    systype = sys_civil
    if( GenieSession.isset( session, :systype ))
        systype = GenieSession.get( session, :systype )
    else
        GenieSession.set!( session, :systype, systype )
    end
    return systype
end

function dict_obs( settings :: Settings )::Observable
    sobs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(sobs) do p
        completed += p.step
        if p.phase ==  "do-session-run-end"
            completed = 0
        end
        prog = Progress( settings.uuid, p.phase, p.thread, completed, p.step, p.size )
        @show "dict_obs: setting PROGRESS[$(settings.uuid)] to $(prog.phase)"
        PROGRESS[settings.uuid] = prog
    end
    return sobs
end 

function session_obs(
    session  :: GenieSession.Session,
    settings :: Settings )::Observable
    sobs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(sobs) do p
        completed += p.step
        if p.phase ==  "do-session-run-end"
            completed = 0
        end
        @info session.id
             @info "in session obs; completed=$completed phase = $(p.phase) session=$(session.id)"
            GenieSession.set!( session, :progress, 
                Progress(
                    p.uuid, 
                    p.phase, 
                    p.thread,
                    completed,
                    p.step,
                    p.size ))
                # (phase=p.phase, completed = completed, size=p.size))
    end
    return sobs
end 
  
function get_params_from_session(session::GenieSession.Session)::AllLASubsys
    systype = systype_from_session( session )
    allsubsys = nothing
    if( GenieSession.isset( session, :allsubsys ))
        allsubsys = GenieSession.get( session, :allsubsys )
    else
        allsubsys = AllLASubsys( DEFAULT_UUID, DEFAULT_PARAMS.legalaid )
        GenieSession.set!( session, :allsubsys, allsubsys )
    end
    return allsubsys
end

function load_all()
    session = GenieSession.session()
    systype = systype_from_session(session)
    resp = from_session(session) # deepcopy( DEFAULT_COMPLETE_RESPONSE )
    # to_session( session, resp )
    return ( response=output_ready, data = OneResponse( systype, resp )) |> json
end

function reset()
    session = GenieSession.session()
    systype = systype_from_session(session)
    resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
    to_session( session, resp )
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json
end

function switch_system()
    session = GenieSession.session()
    systype = systype_from_session(session)
    systype = systype == sys_civil ? sys_aa : sys_civil
    GenieSession.set!( session, :systype, systype )
    resp = from_session(session)
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json
end

"""
return output for the 
"""
function get_output() :: NamedTuple
    session = GenieSession.session()
    systype = systype_from_session(session)
    resp = from_session(session)
    return ( response=output_ready, data = OneResponse( systype, resp))
end

function getprogress( uuid :: UUID ) 
    sess = GenieSession.session()
    systype = systype_from_session(sess)
    @show "getprogress entered looking for uuid=$uuid"
    @show "available keys are: $(keys(PROGRESS))"
    if( haskey( PROGRESS, uuid ))
        @show "getprogress: key $uuid found "
        progress = PROGRESS[uuid]
        @show "getprogress: progress is $progress" 
        if progress.phase == "do-session-run-end" 
            outp = get_output()
            @assert outp.data.params.uuid == uuid "uuid of returned outp wrong requested=$uuid vs in params=$(outp.data.params.uuid)"
            return outp |> json
        else
            return ( response=has_progress, data=progress, systype=systype ) |> json
        end
    else
        @show "getprogress: no progress found"
        progress = NO_PROGRESS 
        return ( response=no_progress, data=NO_PROGRESS, systype=systype ) |> json
    end
end

function getprogress_sess() 
    sess = GenieSession.session()
    @info sess.id
    @info keys(sess.data)        
    systype = systype_from_session(sess)
    @info "getprogress entered"
    if( GenieSession.isset( sess, :progress ))
        @info "getprogress: has progress "
        progress = GenieSession.get( sess, :progress )
        @info progress 
        if progress.phase == "do-session-run-end" 
            return get_output() |> json
        else
            return ( response=has_progress, data=progress, systype=systype ) |> json
        end
    else
        @info "getprogress: no progress"
        # GenieSession.set!( sess, :progress, progress )
        progress = NO_PROGRESS # ( phase="missing", completed = 0, size=0 )
        return ( response=no_progress, data=progress, systype=systype ) |> json
    end
end

"""
Execute a run from the queue.
"""
function do_session_run( session::Session, allsubsys :: AllLASubsys )
    systype = systype_from_session( session )
    activesubsys = systype == sys_civil ? allsubsys.civil : allsubsys.aa    
    settings = make_default_settings()
    # settings.uuid = UUID(rand(UInt128))
    sobs = dict_obs( settings )
    sobs[]= Progress( settings.uuid, "start-pre", -99, -99, -99, -99 )
    sys2 = deepcopy( DEFAULT_PARAMS )
    sys2.legalaid.civil = map_sys_from_subsys( allsubsys.civil )
    sys2.legalaid.aa = map_sys_from_subsys( allsubsys.aa )
    map_settings_from_subsys!( settings, activesubsys )
    @info "dorun entered activesubsys is " activesubsys
    res = do_la_run( settings, DEFAULT_PARAMS, sys2, sobs )
    resp = CompleteResponse(
        res.xlsxfile,
        res.html,
        DEFAULT_SUBSYS,
        allsubsys )       
    to_session( session, resp )
    sobs[]= Progress( settings.uuid, "do-session-run-end", -99, -99, -99, -99 )
    GenieSession.set!( session, :progress, 
        Progress(settings.uuid, "do-session-run-end", -99, -99, -99, -99 ))
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
const NUM_HANDLERS = 4
#
# This number of submissions
#
const QSIZE = 32
struct SubsysAndSession{T}
  subsys  :: AllLASubsys{T}
  session :: GenieSession.Session
end

IN_QUEUE = Channel{SubsysAndSession{Float64}}(QSIZE) # 

function submit_job()
    session = GenieSession.session() 
    systype = systype_from_session(session)
    subsys = subsys_from_payload()
    allsubsys = get_params_from_session(session)
    if subsys.systype == sys_civil 
        allsubsys.civil = subsys
    else 
        allsubsys.aa = subsys
    end
    GenieSession.set!( session, :allsubsys, allsubsys )    
    @info "submit_job subsys=" subsys
    sas = SubsysAndSession(allsubsys,session)
    put!( IN_QUEUE, sas )
    qp = ( phase="queued" ,completed=0, size=0 )
    GenieSession.set!( session, :progress, qp )    
    return ( response=has_progress, data=qp ) |> json
 end

function grab_runs_from_queue()
    while true
        onejob = take!( IN_QUEUE )
        # n = $(size(IN_QUEUE))
        println( "taking run from queue" ) # $n")
        do_session_run( onejob.session, onejob.subsys ) 
    end
end

#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
  @info "starting handler $i"   
  errormonitor( @async grab_runs_from_queue())
end