// Code block + CTA band
function CodeShowcase() {
  return (
    <section style={{ padding: '96px 32px', borderBottom: '1px solid var(--border-subtle)', background: 'var(--bg-sunken)' }}>
      <div style={{ maxWidth: 1120, margin: '0 auto', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 64, alignItems: 'center' }}>
        <div>
          <Eyebrow>the sdk</Eyebrow>
          <h2 style={{ marginTop: 12, marginBottom: 20 }}>from prompt to production in 12 lines.</h2>
          <p style={{ color: 'var(--fg2)', fontSize: 16, maxWidth: 460, marginBottom: 28 }}>
            Define an agent. Pick a chain. Deploy. Rlabs handles key management, model routing, gas abstraction, and onchain audit logs.
          </p>
          <Button variant="primary" iconRight={<Icon name="arrow" size={14}/>}>open quickstart</Button>
        </div>
        <div style={{
          background: 'var(--rl-near-black)', borderRadius: 8,
          overflow: 'hidden', border: '1px solid var(--border-strong)',
          fontFamily: 'var(--font-mono)', fontSize: 13, lineHeight: 1.7,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
            <div style={{ display: 'flex', gap: 6 }}>
              <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#2A2A2E' }}/>
              <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#2A2A2E' }}/>
              <div style={{ width: 10, height: 10, borderRadius: '50%', background: '#2A2A2E' }}/>
            </div>
            <Mono size={11} color="#8A8A92">agent.ts</Mono>
          </div>
          <div style={{ padding: '18px 20px', color: '#C8C8CC' }}>
            <div><span style={{ color: '#8A8A92' }}>import</span> {'{ Agent, chain }'} <span style={{ color: '#8A8A92' }}>from</span> <span style={{ color: '#C6F24E' }}>'@rlabs/sdk'</span></div>
            <div style={{ height: 10 }}/>
            <div><span style={{ color: '#8A8A92' }}>const</span> <span style={{ color: '#FAFAF7' }}>sentry</span> = <span style={{ color: '#8A8A92' }}>new</span> Agent({'{'}
            </div>
            <div style={{ paddingLeft: 20 }}>name: <span style={{ color: '#C6F24E' }}>'mev-sentry'</span>,</div>
            <div style={{ paddingLeft: 20 }}>model: <span style={{ color: '#C6F24E' }}>'claude-haiku-4.5'</span>,</div>
            <div style={{ paddingLeft: 20 }}>chain: chain.<span style={{ color: '#FAFAF7' }}>base</span>,</div>
            <div style={{ paddingLeft: 20 }}>rules: <span style={{ color: '#C6F24E' }}>'./policy.yml'</span>,</div>
            <div>{'}'})</div>
            <div style={{ height: 10 }}/>
            <div><span style={{ color: '#8A8A92' }}>await</span> sentry.<span style={{ color: '#8B5CF6' }}>deploy</span>()</div>
            <div><span style={{ color: '#8A8A92' }}>// ✓ settled 0xA3f9…E21c</span></div>
          </div>
        </div>
      </div>
    </section>
  );
}

function CTABand() {
  return (
    <section style={{ padding: '120px 32px', position: 'relative', overflow: 'hidden' }}>
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: 'linear-gradient(to right, var(--border-subtle) 1px, transparent 1px), linear-gradient(to bottom, var(--border-subtle) 1px, transparent 1px)',
        backgroundSize: '64px 64px', opacity: 0.5,
      }}/>
      <div style={{ position: 'relative', maxWidth: 800, margin: '0 auto', textAlign: 'center' }}>
        <h2 style={{ fontSize: 72, lineHeight: 1, marginBottom: 24 }}>start shipping.</h2>
        <p style={{ color: 'var(--fg2)', fontSize: 18, marginBottom: 36 }}>
          Free to try. No contract. Your first mainnet deploy is on us.
        </p>
        <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
          <Button variant="signal" size="lg" iconRight={<Icon name="arrow" size={16}/>}>create account</Button>
          <Button variant="secondary" size="lg">talk to engineering</Button>
        </div>
      </div>
    </section>
  );
}
Object.assign(window, { CodeShowcase, CTABand });
