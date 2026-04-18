// Dashboard metric cards + chart
function MetricCard({ label, value, delta, deltaTone = 'live', mono }) {
  const tones = { live: '#A9D638', ember: '#FF5B2E', lapis: '#2E5BFF' };
  return (
    <div style={{
      padding: 20, border: '1px solid var(--border-subtle)', borderRadius: 8,
      background: 'var(--bg-elevated)',
    }}>
      <div style={{ fontSize: 12, color: 'var(--fg3)', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 500 }}>{label}</div>
      <div style={{
        fontFamily: mono ? 'var(--font-mono)' : 'var(--font-display)',
        fontWeight: mono ? 500 : 800,
        fontSize: mono ? 26 : 34, letterSpacing: mono ? 0 : '-0.02em',
        marginTop: 10, lineHeight: 1, textTransform: mono ? 'none' : 'lowercase',
      }} className="num">{value}</div>
      {delta && (
        <div style={{ marginTop: 10, fontSize: 12, color: tones[deltaTone], display: 'flex', alignItems: 'center', gap: 4 }}>
          <Icon name="arrowup" size={12} stroke={2}/> {delta}
        </div>
      )}
    </div>
  );
}

function Sparkline() {
  // Static inline SVG sparkline
  const points = [12, 18, 14, 22, 28, 24, 32, 30, 36, 32, 40, 44, 38, 48, 52, 46, 54, 58, 62, 56];
  const max = Math.max(...points), min = Math.min(...points);
  const w = 100, h = 36;
  const pts = points.map((p, i) => {
    const x = (i / (points.length - 1)) * w;
    const y = h - ((p - min) / (max - min)) * h;
    return `${x},${y}`;
  }).join(' ');
  return (
    <svg width="100%" height="40" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      <polyline points={pts} fill="none" stroke="var(--rl-signal)" strokeWidth="1.25" vectorEffect="non-scaling-stroke"/>
    </svg>
  );
}

function Overview() {
  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14 }}>
        <MetricCard label="agents live"  value="12" delta="+2 this week"/>
        <MetricCard label="txns settled 24h" value="4,208" delta="+18.4%"/>
        <MetricCard label="p50 latency" mono value="142ms" delta="-8ms" deltaTone="live"/>
        <MetricCard label="gas spent" mono value="$342" delta="+4.1%" deltaTone="ember"/>
      </div>

      <div style={{ border: '1px solid var(--border-subtle)', borderRadius: 8, background: 'var(--bg-elevated)', padding: 24 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: 20 }}>
          <div>
            <Eyebrow>throughput · 7d</Eyebrow>
            <div style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 40, letterSpacing: '-0.02em', textTransform: 'lowercase', marginTop: 8, lineHeight: 1 }} className="num">28,418 txns</div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {['24h', '7d', '30d', 'all'].map(p => (
              <button key={p} style={{
                fontFamily: 'var(--font-body)', fontSize: 12, fontWeight: 500,
                padding: '5px 10px', borderRadius: 6, border: '1px solid transparent',
                background: p === '7d' ? 'var(--bg-sunken)' : 'transparent',
                color: p === '7d' ? 'var(--fg1)' : 'var(--fg3)',
                cursor: 'pointer',
              }}>{p}</button>
            ))}
          </div>
        </div>
        <div style={{ height: 180, display: 'flex', alignItems: 'flex-end', gap: 2 }}>
          {Array.from({ length: 56 }).map((_, i) => {
            const h = 20 + Math.abs(Math.sin(i * 0.7) * 60) + Math.abs(Math.cos(i * 0.3) * 40);
            const isLive = i > 44;
            return <div key={i} style={{ flex: 1, height: h, background: isLive ? 'var(--rl-signal)' : 'var(--border-strong)', opacity: isLive ? 1 : 0.7 }}/>;
          })}
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { MetricCard, Sparkline, Overview });
