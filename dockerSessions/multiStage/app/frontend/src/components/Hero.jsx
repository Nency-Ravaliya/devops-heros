import React from 'react';
import { DepthIcon, WavesIcon, EyeIcon, TerminalIcon, ShieldCheckIcon } from './Icons';

export const Hero = ({ backendData, loading, onRefreshBackend }) => {
  return (
    <section id="hero" className="relative pt-32 pb-24 overflow-hidden">
      {/* Background Glows and Radials */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[650px] h-[350px] bg-sky-600/10 blur-[130px] rounded-full pointer-events-none -z-10" />
      <div className="absolute top-1/3 left-1/3 w-[300px] h-[200px] bg-cyan-400/10 blur-[90px] rounded-full pointer-events-none -z-10" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Top Tag */}
        <div className="flex justify-center mb-6">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-abyss-900/90 border border-white/10 text-xs font-mono text-soft-muted shadow-sm">
            <span className="w-1.5 h-1.5 rounded-full bg-luminous-cyan animate-pulse"></span>
            <span>Midnight & Abyssal Zone Night Expeditions</span>
          </div>
        </div>

        {/* Hero Heading */}
        <div className="text-center max-w-4xl mx-auto space-y-6">
          <h1 className="text-4xl sm:text-6xl md:text-7xl font-bold tracking-tight text-soft-white leading-tight">
            Confront the Abyss. <br />
            <span className="bg-gradient-to-r from-soft-white via-cyan-200 to-sky-400 bg-clip-text text-transparent glow-text-cyan">
              Embrace the Bioluminescence.
            </span>
          </h1>

          <p className="text-base sm:text-lg text-soft-muted max-w-2xl mx-auto leading-relaxed font-light">
            Biolume curates controlled, high-depth nocturnal oceanic descents. 
            Step past the sunlit surface into pure pitch-black void, where the ancient thrill 
            of oceanic phobias awakens under the eerie glow of deep-sea living light.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-wrap items-center justify-center gap-4 pt-4">
            <a
              href="#phobias"
              className="px-6 py-3 rounded-lg bg-cyan-500/10 text-cyan-300 border border-cyan-400/40 hover:bg-cyan-500/20 hover:border-cyan-300 font-medium text-sm transition-all duration-200 flex items-center gap-2 shadow-glow-sm"
            >
              <EyeIcon className="w-4 h-4 text-cyan-300" />
              Explore Phobia Profiles
            </a>
            
            <a
              href="#contact"
              className="px-6 py-3 rounded-lg bg-abyss-900 hover:bg-abyss-800 text-soft-muted hover:text-soft-white border border-white/10 font-medium text-sm transition-all duration-200 flex items-center gap-2"
            >
              <DepthIcon className="w-4 h-4 text-soft-dim" />
              Book Night Descent
            </a>
          </div>
        </div>

        {/* Backend Connectivity / Telemetry Module */}
        <div className="mt-16 max-w-3xl mx-auto">
          <div className="rounded-xl bg-abyss-900/70 border border-white/10 p-5 backdrop-blur-md glow-border transition-all">
            
            <div className="flex items-center justify-between border-b border-white/5 pb-3 mb-4">
              <div className="flex items-center gap-2 text-xs font-mono text-soft-muted">
                <TerminalIcon className="w-4 h-4 text-luminous-cyan" />
                <span>Biolume Telemetry Link (Node/Express API)</span>
              </div>
              <button
                onClick={onRefreshBackend}
                className="text-[11px] font-mono text-soft-dim hover:text-luminous-cyan transition-colors"
                title="Ping backend"
              >
                {loading ? 'Polling...' : '[Sync Telemetry]'}
              </button>
            </div>

            <div className="space-y-3 font-mono text-xs">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 text-soft-dim">
                <span className="text-soft-muted">Backend Response:</span>
                <span className="text-luminous-cyan">
                  {backendData?.message || (loading ? 'Connecting to Biolume Node.js server...' : 'Offline / Check backend server')}
                </span>
              </div>

              {backendData?.expeditionMetrics && (
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-2 border-t border-white/5">
                  <div className="bg-abyss-950/60 p-2 rounded border border-white/5">
                    <div className="text-[10px] text-soft-dim uppercase">Depth Band</div>
                    <div className="text-soft-white font-medium">{backendData.expeditionMetrics.depthRange}</div>
                  </div>
                  <div className="bg-abyss-950/60 p-2 rounded border border-white/5">
                    <div className="text-[10px] text-soft-dim uppercase">Bioluminescence</div>
                    <div className="text-luminous-teal font-medium">{backendData.expeditionMetrics.bioluminescenceLevel}</div>
                  </div>
                  <div className="bg-abyss-950/60 p-2 rounded border border-white/5">
                    <div className="text-[10px] text-soft-dim uppercase">Active Pods</div>
                    <div className="text-soft-white font-medium">{backendData.expeditionMetrics.activeDives} Submersibles</div>
                  </div>
                  <div className="bg-abyss-950/60 p-2 rounded border border-white/5">
                    <div className="text-[10px] text-soft-dim uppercase">Hull Integrity</div>
                    <div className="text-luminous-cyan font-medium">{backendData.expeditionMetrics.submersibleStatus}</div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Metric Badges */}
        <div id="phobias" className="mt-20 grid grid-cols-1 md:grid-cols-3 gap-6">
          
          <div className="p-6 rounded-xl bg-abyss-900/40 border border-white/5 hover:border-cyan-500/30 transition-all group">
            <div className="w-10 h-10 rounded-lg bg-abyss-800 border border-white/10 flex items-center justify-center text-cyan-400 mb-4 group-hover:border-cyan-500/50">
              <WavesIcon className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-semibold text-soft-white mb-2">Thalassophobia</h3>
            <p className="text-sm text-soft-muted leading-relaxed font-light">
              The fear of vast, boundless, dark waters. At night, surface depth disappears entirely into a sensory vacuum of infinite expanse.
            </p>
            <div className="mt-4 text-xs font-mono text-cyan-400/80">Depth: 200m – 1,000m (Mesopelagic)</div>
          </div>

          <div className="p-6 rounded-xl bg-abyss-900/40 border border-white/5 hover:border-cyan-500/30 transition-all group">
            <div className="w-10 h-10 rounded-lg bg-abyss-800 border border-white/10 flex items-center justify-center text-cyan-400 mb-4 group-hover:border-cyan-500/50">
              <DepthIcon className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-semibold text-soft-white mb-2">Bathophobia & Nyctophobia</h3>
            <p className="text-sm text-soft-muted leading-relaxed font-light">
              The visceral thrill of the bottomless descent. Plunge into the midnight twilight where no sunlight has ever touched in Earth's history.
            </p>
            <div className="mt-4 text-xs font-mono text-cyan-400/80">Depth: 1,000m – 4,000m (Bathypelagic)</div>
          </div>

          <div className="p-6 rounded-xl bg-abyss-900/40 border border-white/5 hover:border-cyan-500/30 transition-all group">
            <div className="w-10 h-10 rounded-lg bg-abyss-800 border border-white/10 flex items-center justify-center text-cyan-400 mb-4 group-hover:border-cyan-500/50">
              <ShieldCheckIcon className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-semibold text-soft-white mb-2">Megalohydrothalassophobia</h3>
            <p className="text-sm text-soft-muted leading-relaxed font-light">
              Encounters in total blackout with gargantuan siphonophores, colossal squids, and glowing benthic fauna illuminated solely by bio-pulses.
            </p>
            <div className="mt-4 text-xs font-mono text-cyan-400/80">Depth: 4,000m – 11,000m (Hadal Abyss)</div>
          </div>

        </div>

      </div>
    </section>
  );
};
