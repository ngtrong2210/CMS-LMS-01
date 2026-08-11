import { describe,expect,it,vi } from 'vitest'
import { createInteractionEngine,normalizeInteractions } from './useVideoInteractions'

const interaction=(id,timeSeconds,extra={})=>({id,questionId:id,timeSeconds,label:`Câu ${id}`,required:true,pauseVideo:true,...extra})

describe('interactive video engine',()=>{
  it('normalizes, sorts and skips invalid interactions',()=>{
    const warn=vi.spyOn(console,'warn').mockImplementation(()=>{})
    expect(normalizeInteractions([interaction(2,20),interaction(1,5),{id:0,timeSeconds:2}]).map(x=>x.id)).toEqual([1,2])
    warn.mockRestore()
  })

  it('triggers when playback crosses a marker and never triggers it twice',()=>{
    const engine=createInteractionEngine([interaction(1,20)])
    engine.loadAt(19.7)
    expect(engine.tick(20.2)?.id).toBe(1)
    expect(engine.continue()).toBeNull()
    expect(engine.tick(21)).toBeNull()
  })

  it('triggers timestamp zero on first play',()=>{
    const engine=createInteractionEngine([interaction(1,0)])
    expect(engine.start(0)?.id).toBe(1)
    expect(engine.start(0)).toBeNull()
  })

  it('queues all interactions at the same timestamp',()=>{
    const engine=createInteractionEngine([interaction(1,10),interaction(2,10)])
    expect(engine.tick(10)?.id).toBe(1)
    expect(engine.continue()?.id).toBe(2)
    expect(engine.continue()).toBeNull()
  })

  it('does not trigger crossed markers while seeking',()=>{
    const engine=createInteractionEngine([interaction(1,20)])
    engine.loadAt(10);engine.beginSeek()
    expect(engine.tick(30)).toBeNull()
    engine.endSeek(30)
    expect(engine.tick(31)).toBeNull()
  })

  it('cannot close a required interaction and resets cleanly for a new route',()=>{
    const engine=createInteractionEngine([interaction(1,5)])
    expect(engine.tick(5)?.id).toBe(1)
    expect(engine.close()).toBe(false)
    engine.reset([interaction(2,3)])
    expect(engine.tick(3)?.id).toBe(2)
  })

  it('skips answered interactions on replay',()=>{
    const engine=createInteractionEngine([interaction(1,5,{answered:true})],[1])
    engine.loadAt(0)
    expect(engine.tick(6)).toBeNull()
  })
})
