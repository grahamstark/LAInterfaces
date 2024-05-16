
# ==== Queue stuff

const CACHED_RESULTS = LRU{AllLASubsys,Any}(maxsize=25)

function systype_from_session()
    session = GenieSession.session()
    systype = civil
    if( GenieSession.isset( session, :systype ))
        systype = GenieSession.get( session, :systype )
    else
        GenieSession.set!( session, :systype, systype )
    end
    return systype
end

function getprogress() 
    sess = GenieSession.session()
    systype = systype_from_session()
    @info "getprogress entered"
    progress = ( phase="missing", completed = 0, size=0 )
    if( GenieSession.isset( sess, :progress ))
        @info "getprogress: has progress"
        progress = GenieSession.get( sess, :progress )
    else
        @info "getprogress: no progress"
        GenieSession.set!( sess, :progress, progress )
    end
    
    ( response=has_progress, data=progress, systype=systype ) |> json
end
  
function session_obs(session::GenieSession.Session)::Observable
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(obs) do p
        if p.phase == "do-one-run-end"
            completed = 0
        end
        completed += p.step
        @info "monitor completed=$completed p = $(p)"
        GenieSession.set!( session, :progress, (phase=p.phase, completed = completed, size=p.size))
    end
    return obs
end 
  
function screen_obs()::Observable
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
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
  
function get_params_from_session()::AllLASubsys
    session = GenieSession.session()
    systype = systype_from_session()
    allsubsys = nothing
    if( GenieSession.isset( session, :allsubsys ))
        allsubsys = GenieSession.get( session, :allsubsys )
    else
        allsubsys = AllLASubSys( DEFAULT_PARAMS.legalaid )
        GenieSession.set!( session, :allsubsys, allsubsys )
    end
    return allsubsys
end

function reset()
    session = GenieSession.session()
    systype = systype_from_session()
    allsubsys = AllLASubsys( DEFAULT_PARAMS.legalaid )
    GenieSession.set!( session, :allsubsys, allsubsys )

end

"""
Execute a run from the queue.
"""
function dorun( session::Session, allsubsys :: AllLASubsys )
    systype = systype_from_session()
    settings = make_default_settings()  
    lasys = map_sys_from_subsys( subsys )
    sys2 = deepcopy( DEFAULT_PARAMS )
    # allsubsys = get_params_from_session()
    if subsys.systype == sys_civil 
        sys2.legalaid.civil = lasys
        allsubsys.civil = subsys
    else 
        sys2.legalaid.aa = lasys
        allsubsys.aa = subsys
    end
    GenieSession.set!( session, :systype, subsys.systype )
    GenieSession.set!( session, :allsubsys, allsubsys )
    default_subsys =AllLASubSys( DEFAULT_PARAMS.legalaid )
    map_settings_from_subsys!( settings, subsys )
    @info "dorun entered subsys is " subsys
    obs = session_obs(session)
    results = Runner.do_one_run( settings, [DEFAULT_PARAMS,sys2], obs )
    outf = summarise_frames!( results, settings )
    html = all_results_to_html( outf.legalaid, sys2.legalaid ) 
    if subsys.systype == sys_civil 
        xlsxfile = export_xlsx( results.legalaid.civil )
    else
        xlsxfile = export_xlsx( results.legalaid.aa )
    end
    output = (; html, xlsfile, params=allsubsys, defaults=default_subsys )
    obs[]=Progress( settings.uuid, "results-generation", 0, 0, 0, 0 )   
    CACHED_RESULTS[allsubsys]=output
    GenieSession.set!( :allsubsys, allsubsys ) 
    GenieSession.set!( :output, output )
    obs[]= Progress( settings.uuid, "end", -99, -99, -99, -99 )
end

function get_output_from_cache()
    systype = systype_from_session()
    params = get_params_from_session()         
    if has_key( CACHED_RESULTS, params )
        @info "found cached results"
        output = CACHED_RESULTS[params]
        return ( response=output_ready, data=output)  
    end
    @info "responding with bad_request" 
    return( response=bad_request, data="" )  
end

function get_output_from_session()
    systype = systype_from_session()
    if systype == civil
        
    else

    end
end

"""
return output for the 
"""
function getoutput() 
    # fixme addd 1 session & reuse 
    systype = systype_from_session()
    alloutput = get_output_from_session()
    allsubsys = get_subsys_from_session()
    # utput = (; html, xlsfile, params=allsubsys, defaults=default_subsys )
    if systype == civil
        return (; html=html.civil, subsys=allsubsys.civil, defaults=defaults.civil, xlsfile=xlsfile, systype=systype ) |> json
    else
        return (; html=html.aa, subsys=allsubsys.aa, defaults=defaults.aa, xlsfile=aa, systype=systype ) |> json
    end
end

function switch()
    systype = systype_from_session()
    systype = systype == civil ? aa : civil
    GenieSession.set!( session, :systype, systype )
     |> json 
end
  
function submit_job()
    systype = systype_from_session()
    session = GenieSession.session() #  :: GenieSession.Session 
    subsys = subsys_from_payload()
    allsubsys = get_params_from_session()
    if subsys.systype == sys_civil 
        allsubsys.civil = subsys
    else 
        allsubsys.aa = subsys
    end
    GenieSession.set!( session, :allsubsys, allsubsys )    
    @info "submit_job facs=" facs
    if ! haskey( CACHED_RESULTS, allsubsys )    
        put!( IN_QUEUE, allsubsys )
        qp = ( phase="queued" ,completed=0, size=0 )
        GenieSession.set!( session, :progress, qp )    
        return ( response=has_progress, data=qp ) |> json
    else
        GenieSession.set!( session, :progress, (phase="end",completed=0, size=0 ))
        return ( response=output_ready, data=get_output_from_cache()) |> json      
    end
end
  
struct SubsysAndSession{T}
    subsys  :: AllLASubsys{T}
    session :: GenieSession.Session
end
  
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 2
#
# This number of submissions
#
const QSIZE = 32

IN_QUEUE = Channel{SubsysAndSession}(QSIZE)

"""
"""
function grab_runs_from_queue()
    while true
        params = take!( IN_QUEUE )
        dorun( params.session, params.subsys ) 
    end
end


#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
    @info "starting handler $i" 
    errormonitor(@async grab_runs_from_queue())
end

