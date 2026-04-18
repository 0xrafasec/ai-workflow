// Agents list + detail
function AgentRow({ name, model, chain, status, txns, last }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1.5fr 1fr 1fr 1fr 1fr 28px',
      gap: 16, alignItems: 'center', padding: '14px 20px',
      borderBottom: '1px solid var(--border-subtle)', cursor: 'pointer',
      transition: `background 200ms ${EASE}`,
    }}
      onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-sunken)'}
      onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ width: 28, height: 28, borderRadius: 6, background: 'var(--bg-sunken)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--fg2)' }}>
          <Icon name="cpu" size={14}/>
        </div>
        <div style={{ fontWeight: 500 }}>{name}</div>
      </div>
      <Mono>{model}</Mono>
      <Mono>{chain}</Mono>
      <Badge tone={status === 'live' ? 'live' : status === 'failed' ? 'ember' : 'lapis'}>{status}</Badge>
      <div style={{ fontFamily: 'var(--font-mono)', fontSize: 13 }} className="num">{txns}</div>
      <div style={{ color: 'var(--fg3)' }}><Icon name="arrow" size={14}/></div>
    </div>
  );
}

function Agents() {
  const agents = [
    { name: 'mev-sentry-01',   model: 'claude-haiku-4.5', chain: 'base',     status: 'live',    txns: '2,118' },
    { name: 'arb-hawk-mainnet',model: 'gpt-4o',           chain: 'ethereum', status: 'live',    txns: '1,402' },
    { name: 'vault-guardian',  model: 'claude-sonnet-4',  chain: 'base',     status: 'live',    txns: '812' },
    { name: 'dao-clerk',       model: 'llama-3.1-70b',    chain: 'arbitrum', status: 'pending', txns: '0' },
    { name: 'rpc-canary-sol',  model: 'claude-haiku-4.5', chain: 'solana',   status: 'live',    txns: '3,204' },
    { name: 'liq-watcher-v2',  model: 'gpt-4o-mini',      chain: 'base',     status: 'failed',  txns: '12' },
  ];
  return (
    <div style={{ padding: 32 }}>
      <div style={{ border: '1px solid var(--border-subtle)', borderRadius: 8, background: 'var(--bg-elevated)', overflow: 'hidden' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1.5fr 1fr 1fr 1fr 1fr 28px', gap: 16,
          padding: '12px 20px', borderBottom: '1px solid var(--border-subtle)',
          background: 'var(--bg-sunken)',
        }}>
          {['agent', 'model', 'chain', 'status', 'txns 24h', ''].map(h => (
            <div key={h} style={{ fontSize: 11, color: 'var(--fg3)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 500 }}>{h}</div>
          ))}
        </div>
        {agents.map(a => <AgentRow key={a.name} {...a}/>)}
      </div>
    </div>
  );
}
Object.assign(window, { AgentRow, Agents });
