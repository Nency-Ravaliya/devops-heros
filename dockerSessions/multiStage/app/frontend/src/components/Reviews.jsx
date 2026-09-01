import React from 'react';
import { CompassIcon, EyeIcon, MoonIcon } from './Icons';

const REVIEW_LOGS = [
  {
    id: "dive-log-842",
    author: "Elena Vance",
    role: "Nocturnal Expedition Diver",
    location: "Kermadec Trench (6,200m)",
    title: "When the Sub Lights Went Dark",
    excerpt: "At 6,000 meters down, our dive master killed the external floodlights for three minutes. You realize how vast and cold nothingness truly is. Then, a single bioluminescent jellyfish lit up right against the viewport. Chills went down my entire spine.",
    diveProfile: {
      depth: "6,200m",
      duration: "4h 30m",
      phobiaFaced: "Thalassophobia"
    },
    date: "August 2026"
  },
  {
    id: "dive-log-719",
    author: "Marcus Thorne",
    role: "Acoustic Bio-researcher & Diver",
    location: "Mariana Horizon (8,450m)",
    title: "Descending Through the Midnight Zone",
    excerpt: "I've had bathophobia since childhood. Entering the pitch-black Bathypelagic zone at 2 AM aboard the Biolume pod forced me to stare into the abyss. It is terrifying yet strangely the most tranquil experience on planet Earth.",
    diveProfile: {
      depth: "8,450m",
      duration: "5h 15m",
      phobiaFaced: "Bathophobia"
    },
    date: "July 2026"
  },
  {
    id: "dive-log-603",
    author: "Sarah K. Jenkins",
    role: "Extreme Adventure Photographer",
    location: "Monterey Abyssal Canyon (3,100m)",
    title: "The Living Blue Constellation",
    excerpt: "Forget stars in the sky—the real galaxies are underwater at night. Swimming in an atmospheric dive suit surrounded by flashing emerald-blue siphonophore ribbons redefined my understanding of darkness.",
    diveProfile: {
      depth: "3,100m",
      duration: "3h 40m",
      phobiaFaced: "Nyctophobia"
    },
    date: "June 2026"
  }
];

export const Reviews = () => {
  return (
    <section id="reviews" className="py-24 relative border-t border-white/5 bg-abyss-950/60">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-950/40 border border-cyan-500/20 text-xs font-mono text-cyan-400">
            <MoonIcon className="w-3.5 h-3.5" />
            <span>Expedition Logs & Diver Testimonials</span>
          </div>
          
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-soft-white">
            Unfiltered Stories from the Depths
          </h2>
          
          <p className="text-sm sm:text-base text-soft-muted font-light">
            Read firsthand accounts from divers who ventured into the absolute nocturnal void 
            and confronted their oceanic phobias.
          </p>
        </div>

        {/* Review Log Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {REVIEW_LOGS.map((log) => (
            <article 
              key={log.id} 
              className="flex flex-col justify-between rounded-xl bg-abyss-900/60 border border-white/5 p-6 hover:border-cyan-500/30 transition-all duration-300 group hover:-translate-y-1 shadow-sm"
            >
              <div>
                {/* Meta Badge */}
                <div className="flex items-center justify-between text-xs font-mono text-soft-dim pb-4 border-b border-white/5 mb-4">
                  <span className="text-cyan-400/90">{log.id}</span>
                  <span>{log.date}</span>
                </div>

                <h3 className="text-lg font-semibold text-soft-white group-hover:text-cyan-300 transition-colors mb-3">
                  "{log.title}"
                </h3>

                <p className="text-sm text-soft-muted leading-relaxed font-light mb-6">
                  {log.excerpt}
                </p>
              </div>

              <div>
                {/* Diver Profile Footer */}
                <div className="pt-4 border-t border-white/5">
                  <div className="grid grid-cols-2 gap-2 text-[11px] font-mono text-soft-dim mb-4 bg-abyss-950/80 p-2.5 rounded border border-white/5">
                    <div>
                      <span className="block text-soft-dim">Depth:</span>
                      <span className="text-soft-white">{log.diveProfile.depth}</span>
                    </div>
                    <div>
                      <span className="block text-soft-dim">Phobia:</span>
                      <span className="text-cyan-400">{log.diveProfile.phobiaFaced}</span>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-cyan-950 border border-cyan-500/30 flex items-center justify-center text-cyan-300 text-xs font-mono">
                      {log.author.split(' ').map(n => n[0]).join('')}
                    </div>
                    <div>
                      <h4 className="text-xs font-medium text-soft-white">{log.author}</h4>
                      <p className="text-[11px] text-soft-dim font-light">{log.role}</p>
                    </div>
                  </div>
                </div>

              </div>
            </article>
          ))}
        </div>

        {/* Safety & Protocol Banner */}
        <div className="mt-16 p-6 rounded-xl bg-gradient-to-r from-abyss-900/80 via-abyss-800/40 to-abyss-900/80 border border-white/5 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-abyss-950 border border-cyan-500/30 flex items-center justify-center text-cyan-400 shrink-0">
              <CompassIcon className="w-6 h-6" />
            </div>
            <div>
              <h4 className="text-sm font-semibold text-soft-white">Triton Atmospheric Submersibles</h4>
              <p className="text-xs text-soft-muted font-light mt-0.5">
                Every nocturnal descent is operated inside pressure-rated titanium-acrylic capsules with redundant life support and neuro-calm protocols.
              </p>
            </div>
          </div>
          <a
            href="#contact"
            className="px-4 py-2 text-xs font-mono text-cyan-300 border border-cyan-400/30 hover:bg-cyan-500/10 rounded-md transition-colors whitespace-nowrap"
          >
            Review Safety Protocols
          </a>
        </div>

      </div>
    </section>
  );
};
