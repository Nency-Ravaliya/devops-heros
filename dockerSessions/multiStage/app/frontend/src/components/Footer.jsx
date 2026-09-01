import React from 'react';
import { CompassIcon, AnchorIcon, WavesIcon } from './Icons';

export const Footer = () => {
  return (
    <footer className="border-t border-white/5 bg-abyss-950/90 py-12 text-soft-dim text-xs font-mono">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8 pb-8 border-b border-white/5">
          
          {/* Col 1 */}
          <div className="space-y-3">
            <div className="flex items-center gap-2 text-soft-white">
              <CompassIcon className="w-4 h-4 text-cyan-400" />
              <span className="font-semibold tracking-wider">BIOLUME</span>
            </div>
            <p className="text-[11px] font-sans text-soft-muted font-light leading-relaxed">
              Nocturnal abyssal exploration and psychological deep-sea exposure platforms.
            </p>
          </div>

          {/* Col 2 */}
          <div className="space-y-2">
            <div className="text-soft-white font-medium">Expeditions</div>
            <ul className="space-y-1 text-[11px]">
              <li><a href="#phobias" className="hover:text-cyan-400 transition-colors">Mesopelagic Twilight</a></li>
              <li><a href="#phobias" className="hover:text-cyan-400 transition-colors">Midnight Zone Plunge</a></li>
              <li><a href="#phobias" className="hover:text-cyan-400 transition-colors">Abyssal Bioluminescence</a></li>
              <li><a href="#phobias" className="hover:text-cyan-400 transition-colors">Hadal Trench Descent</a></li>
            </ul>
          </div>

          {/* Col 3 */}
          <div className="space-y-2">
            <div className="text-soft-white font-medium">Safety Protocols</div>
            <ul className="space-y-1 text-[11px]">
              <li><span className="text-soft-dim">DNV-GL Hull Standards</span></li>
              <li><span className="text-soft-dim">Dual Oxygen Scrubbers</span></li>
              <li><span className="text-soft-dim">Acoustic Positioning Telemetry</span></li>
              <li><span className="text-soft-dim">Controlled Phobia Exposure</span></li>
            </ul>
          </div>

          {/* Col 4 */}
          <div className="space-y-2">
            <div className="text-soft-white font-medium">Telemetry Grid</div>
            <p className="text-[11px] font-mono text-soft-dim">
              LAT: 36°47'24" N<br />
              LON: 122°00'36" W<br />
              PRESSURE: 1,100 ATM MAX
            </p>
          </div>

        </div>

        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-[11px]">
          <div className="flex items-center gap-2">
            <AnchorIcon className="w-3.5 h-3.5 text-cyan-500/60" />
            <span>&copy; {new Date().getFullYear()} Biolume Exploration Corp. All systems nominal.</span>
          </div>
          <div className="flex items-center gap-4 text-soft-dim">
            <span>DevOps-Ready Microservices Architecture</span>
            <span>•</span>
            <span className="text-cyan-400/70">React + Vite + Node/Express</span>
          </div>
        </div>

      </div>
    </footer>
  );
};
