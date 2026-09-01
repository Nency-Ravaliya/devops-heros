import React, { useState } from 'react';
import { MailIcon, MapPinIcon, SendIcon, ShieldCheckIcon, RadioIcon } from './Icons';

export const Contact = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phobiaFocus: 'thalassophobia',
    targetDepth: 'bathy',
    message: ''
  });
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name || !formData.email) return;
    setSubmitted(true);
  };

  return (
    <section id="contact" className="py-24 relative border-t border-white/5 bg-abyss-950">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-950/40 border border-cyan-500/20 text-xs font-mono text-cyan-400">
            <RadioIcon className="w-3.5 h-3.5 animate-pulse" />
            <span>Launch Base & Booking Inquiries</span>
          </div>

          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-soft-white">
            Plan Your Nocturnal Descent
          </h2>

          <p className="text-sm sm:text-base text-soft-muted font-light">
            Ready to confront the deep ocean at night? Connect with our expedition flight directors.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 max-w-6xl mx-auto">
          
          {/* Left Column: Expedition Details */}
          <div className="lg:col-span-5 space-y-6">
            
            <div className="p-6 rounded-xl bg-abyss-900/50 border border-white/5 space-y-4">
              <h3 className="text-base font-semibold text-soft-white flex items-center gap-2">
                <MapPinIcon className="w-4 h-4 text-cyan-400" />
                Nocturnal Departure Stations
              </h3>
              
              <div className="space-y-3 text-xs font-mono text-soft-muted">
                <div className="p-3 rounded bg-abyss-950/80 border border-white/5">
                  <div className="text-soft-white font-medium">Station Alpha: Monterey Subsea Trench</div>
                  <div className="text-soft-dim mt-0.5">Coords: 36.79° N, 122.01° W • Depth: 3,600m</div>
                </div>
                <div className="p-3 rounded bg-abyss-950/80 border border-white/5">
                  <div className="text-soft-white font-medium">Station Omega: Mariana Abyss Horizon</div>
                  <div className="text-soft-dim mt-0.5">Coords: 11.34° N, 142.20° E • Depth: 10,920m</div>
                </div>
              </div>
            </div>

            <div className="p-6 rounded-xl bg-abyss-900/50 border border-white/5 space-y-4">
              <h3 className="text-base font-semibold text-soft-white flex items-center gap-2">
                <MailIcon className="w-4 h-4 text-cyan-400" />
                Direct Dispatch Channel
              </h3>
              <p className="text-xs text-soft-muted font-light leading-relaxed">
                Our support team is staffed by licensed deep-submergence pilots and clinical phobia psychologists.
              </p>
              <div className="text-xs font-mono text-cyan-300">
                inquiries@biolume-abyss.io
              </div>
            </div>

            <div className="p-4 rounded-lg bg-cyan-950/20 border border-cyan-500/20 flex items-start gap-3">
              <ShieldCheckIcon className="w-5 h-5 text-cyan-400 shrink-0 mt-0.5" />
              <p className="text-xs text-soft-dim leading-relaxed">
                All dives comply with DNV-GL deep-sea human-occupancy safety certifications. Full medical and psychological clearance required prior to embarkation.
              </p>
            </div>

          </div>

          {/* Right Column: Interactive Form */}
          <div className="lg:col-span-7">
            <div className="p-8 rounded-xl bg-abyss-900/60 border border-white/10 glow-border">
              
              {submitted ? (
                <div className="py-12 text-center space-y-4">
                  <div className="w-12 h-12 rounded-full bg-cyan-950 border border-cyan-400/40 text-cyan-400 flex items-center justify-center mx-auto">
                    <ShieldCheckIcon className="w-6 h-6" />
                  </div>
                  <h3 className="text-lg font-semibold text-soft-white">Descent Request Dispatched</h3>
                  <p className="text-xs text-soft-muted max-w-md mx-auto font-light leading-relaxed">
                    Thank you, <span className="text-soft-white font-medium">{formData.name}</span>. Our expedition coordinator has received your telemetry and will contact <span className="text-soft-white font-medium">{formData.email}</span> with flight availability and medical orientation materials.
                  </p>
                  <button
                    onClick={() => {
                      setSubmitted(false);
                      setFormData({ name: '', email: '', phobiaFocus: 'thalassophobia', targetDepth: 'bathy', message: '' });
                    }}
                    className="mt-4 px-4 py-2 text-xs font-mono text-cyan-300 border border-cyan-400/30 rounded-md hover:bg-cyan-500/10 transition-colors"
                  >
                    [Send Another Request]
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-5">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-mono text-soft-muted mb-1.5">Your Name</label>
                      <input
                        type="text"
                        required
                        placeholder="Commander J. Doe"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        className="w-full px-3.5 py-2.5 rounded-lg bg-abyss-950 border border-white/10 text-sm text-soft-white placeholder-soft-dim focus:outline-none focus:border-cyan-400/80 transition-colors"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-mono text-soft-muted mb-1.5">Communication Email</label>
                      <input
                        type="email"
                        required
                        placeholder="pilot@domain.com"
                        value={formData.email}
                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                        className="w-full px-3.5 py-2.5 rounded-lg bg-abyss-950 border border-white/10 text-sm text-soft-white placeholder-soft-dim focus:outline-none focus:border-cyan-400/80 transition-colors"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-mono text-soft-muted mb-1.5">Phobia Exploration Focus</label>
                      <select
                        value={formData.phobiaFocus}
                        onChange={(e) => setFormData({ ...formData, phobiaFocus: e.target.value })}
                        className="w-full px-3.5 py-2.5 rounded-lg bg-abyss-950 border border-white/10 text-sm text-soft-white focus:outline-none focus:border-cyan-400/80 transition-colors"
                      >
                        <option value="thalassophobia">Thalassophobia (Open Void)</option>
                        <option value="bathophobia">Bathophobia (Abyssal Depth)</option>
                        <option value="nyctophobia">Nyctophobia (Oceanic Blackout)</option>
                        <option value="megalohydro">Megalohydro (Deep Creatures)</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-xs font-mono text-soft-muted mb-1.5">Target Depth Zone</label>
                      <select
                        value={formData.targetDepth}
                        onChange={(e) => setFormData({ ...formData, targetDepth: e.target.value })}
                        className="w-full px-3.5 py-2.5 rounded-lg bg-abyss-950 border border-white/10 text-sm text-soft-white focus:outline-none focus:border-cyan-400/80 transition-colors"
                      >
                        <option value="meso">Mesopelagic (200m – 1,000m)</option>
                        <option value="bathy">Bathypelagic (1,000m – 4,000m)</option>
                        <option value="abyssal">Abyssopelagic (4,000m – 6,000m)</option>
                        <option value="hadal">Hadal Horizon (6,000m+ Trench)</option>
                      </select>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-mono text-soft-muted mb-1.5">Expedition Notes / Questions</label>
                    <textarea
                      rows={3}
                      placeholder="Share your goals, previous dive certifications, or specific fears to explore..."
                      value={formData.message}
                      onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                      className="w-full px-3.5 py-2.5 rounded-lg bg-abyss-950 border border-white/10 text-sm text-soft-white placeholder-soft-dim focus:outline-none focus:border-cyan-400/80 transition-colors resize-none"
                    ></textarea>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3 rounded-lg bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-300 border border-cyan-400/40 hover:border-cyan-300 font-medium text-sm transition-all duration-200 flex items-center justify-center gap-2 shadow-glow-sm"
                  >
                    <SendIcon className="w-4 h-4" />
                    Transmit Expedition Request
                  </button>
                </form>
              )}

            </div>
          </div>

        </div>

      </div>
    </section>
  );
};
