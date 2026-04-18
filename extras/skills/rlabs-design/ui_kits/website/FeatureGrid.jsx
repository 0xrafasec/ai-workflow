// Feature grid
function FeatureGrid() {
  const features = [
    { icon: 'cpu',      title: 'onchain agents',   body: 'autonomous reasoning with provable action history. every decision settles to a chain of your choice.' },
    { icon: 'shield',   title: 'verifiable by default', body: 'cryptographic receipts for every inference. no black boxes, no trust-me-bro.' },
    { icon: 'link',     title: 'chain-agnostic',   body: 'ethereum, base, solana, cosmos, and custom L2s. one api, seven networks, zero rewrites.' },
    { icon: 'activity', title: 'live observability', body: 'token-level traces, gas accounting, and MEV detection streamed as fast as your agent thinks.' },
    { icon: 'box',      title: 'model-agnostic',   body: 'bring your own model, or use our hosted stack. openai, anthropic, open weights — all welcome.' },
    { icon: 'zap',      title: 'ships in a day',   body: 'sdk, cli, studio, and a cursor agent. go from prompt to production without writing contract glue.' },
  ];
  return (
    <section style={{ padding: '96px 32px', borderBottom: '1px solid var(--border-subtle)' }}>
      <div style={{ maxWidth: 1120, margin: '0 auto' }}>
        <Eyebrow>what we build</Eyebrow>
        <h2 style={{ marginTop: 12, marginBottom: 56, maxWidth: 700 }}>
          six primitives. one trustworthy agent layer.
        </h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 0 }}>
          {features.map((f, i) => (
            <div key={f.title} style={{
              padding: 32,
              borderRight: (i % 3 !== 2) ? '1px solid var(--border-subtle)' : 'none',
              borderBottom: i < 3 ? '1px solid var(--border-subtle)' : 'none',
            }}>
              <div style={{ marginBottom: 20, color: 'var(--fg1)' }}><Icon name={f.icon} size={24}/></div>
              <h3 style={{ fontSize: 22, marginBottom: 10 }}>{f.title}</h3>
              <p style={{ color: 'var(--fg2)', fontSize: 14, lineHeight: 1.6, margin: 0 }}>{f.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
Object.assign(window, { FeatureGrid });
