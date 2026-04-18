// Transactions list
function TxRow({ hash, agent, chain, block, status, value, time }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '1.4fr 1.2fr 1fr 1fr 0.8fr 1fr 1fr',
      gap: 16, alignItems: 'center', padding: '13px 20px',
      borderBottom: '1px solid var(--border-subtle)',
    }}>
      <Mono color="var(--fg1)">{hash}</Mono>
      <div style={{ fontSize: 13 }}>{agent}</div>
      <Mono>{chain}</Mono>
      <Mono>#{block}</Mono>
      <Badge tone={status === 'settled' ? 'live' : status === 'reverted' ? 'ember' : 'lapis'}>{status}</Badge>
      <Mono color="var(--fg1)">{value}</Mono>
      <Mono color="var(--fg3)">{time}</Mono>
    </div>
  );
}
function Transactions() {
  const rows = [
    { hash: '0xA3f9…E21c', agent: 'mev-sentry-01',    chain: 'base',     block: '18204911', status: 'settled',  value: '0.42 ETH',  time: '12s ago' },
    { hash: '0x8c12…7b9d', agent: 'arb-hawk-mainnet', chain: 'ethereum', block: '18204902', status: 'settled',  value: '1.08 ETH',  time: '46s ago' },
    { hash: '0x44ae…91f0', agent: 'rpc-canary-sol',   chain: 'solana',   block: '283910421',status: 'settled',  value: '12.4 SOL',  time: '1m ago'  },
    { hash: '0xde03…b4a1', agent: 'vault-guardian',   chain: 'base',     block: '18204845', status: 'pending',  value: '0.09 ETH',  time: '2m ago'  },
    { hash: '0x1fa2…00dd', agent: 'liq-watcher-v2',   chain: 'base',     block: '18204830', status: 'reverted', value: '—',         time: '4m ago'  },
    { hash: '0x77b2…cc3e', agent: 'mev-sentry-01',    chain: 'base',     block: '18204811', status: 'settled',  value: '0.38 ETH',  time: '6m ago'  },
    { hash: '0x5f09…2aa7', agent: 'arb-hawk-mainnet', chain: 'ethereum', block: '18204789', status: 'settled',  value: '0.61 ETH',  time: '8m ago'  },
  ];
  return (
    <div style={{ padding: 32 }}>
      <div style={{ border: '1px solid var(--border-subtle)', borderRadius: 8, background: 'var(--bg-elevated)', overflow: 'hidden' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1.4fr 1.2fr 1fr 1fr 0.8fr 1fr 1fr', gap: 16,
          padding: '12px 20px', borderBottom: '1px solid var(--border-subtle)',
          background: 'var(--bg-sunken)',
        }}>
          {['hash', 'agent', 'chain', 'block', 'status', 'value', 'time'].map(h => (
            <div key={h} style={{ fontSize: 11, color: 'var(--fg3)', textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 500 }}>{h}</div>
          ))}
        </div>
        {rows.map(r => <TxRow key={r.hash} {...r}/>)}
      </div>
    </div>
  );
}
Object.assign(window, { Transactions });
