import React from 'react';
import { CompassIcon, RadioIcon } from './Icons';

export const Navbar = ({ backendStatus }) => {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-abyss-950/80 backdrop-blur-md border-b border-white/5 transition-all">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        
        {/* Brand */}
        <a href="#hero" className="flex items-center gap-3 group">
          <div className="w-8 h-8 rounded-lg bg-abyss-900 border border-luminous-cyan/40 flex items-center justify-center text-luminous-cyan shadow-glow-sm group-hover:border-luminous-cyan transition-colors">
            <CompassIcon className="w-4 h-4" />
          </div>
          <div className="flex flex-col">
            <span className="text-lg font-semibold tracking-wider text-soft-white group-hover:text-luminous-cyan transition-colors">
              BIOLUME
            </span>
            <span className="text-[10px] tracking-widest uppercase text-soft-dim font-mono">
              Night Abyssal Diving
            </span>
          </div>
        </a>

        {/* Navigation */}
        <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-soft-muted">
          <a href="#hero" className="hover:text-soft-white hover:text-luminous-cyan transition-colors">
            Overview
          </a>
          <a href="#phobias" className="hover:text-soft-white hover:text-luminous-cyan transition-colors">
            The Abyss
          </a>
          <a href="#reviews" className="hover:text-soft-white hover:text-luminous-cyan transition-colors">
            Expedition Logs
          </a>
          <a href="#contact" className="hover:text-soft-white hover:text-luminous-cyan transition-colors">
            Inquire
          </a>
        </nav>

        {/* Backend Status Indicator */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-abyss-900/90 border border-white/10 text-xs font-mono">
            <span className="relative flex h-2 w-2">
              <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${
                backendStatus.connected ? 'bg-luminous-teal' : 'bg-amber-500'
              }`}></span>
              <span className={`relative inline-flex rounded-full h-2 w-2 ${
                backendStatus.connected ? 'bg-luminous-teal' : 'bg-amber-500'
              }`}></span>
            </span>
            <span className="text-soft-muted hidden sm:inline">API Core:</span>
            <span className={backendStatus.connected ? 'text-luminous-teal' : 'text-amber-400'}>
              {backendStatus.connected ? 'LIVE' : 'STANDBY'}
            </span>
          </div>

          <a 
            href="#contact" 
            className="hidden sm:inline-flex items-center justify-center px-4 py-1.5 text-xs font-medium tracking-wide uppercase rounded-md bg-luminous-cyan/10 text-luminous-cyan border border-luminous-cyan/30 hover:bg-luminous-cyan/20 hover:border-luminous-cyan transition-all"
          >
            Book Descent
          </a>
        </div>

      </div>
    </header>
  );
};
