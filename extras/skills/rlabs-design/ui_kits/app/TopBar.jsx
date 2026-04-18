// Dashboard topbar
function TopBar({ title, subtitle }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '20px 32px', borderBottom: '1px solid var(--border-subtle)',
      background: 'var(--bg)',
    }}>
      <div>
        <Eyebrow>{subtitle}</Eyebrow>
        <h2 style={{ fontSize: 28, marginTop: 4, lineHeight: 1 }}>{title}</h2>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          border: '1px solid var(--border-subtle)', borderRadius: 8,
          padding: '7px 12px', color: 'var(--fg3)',
        }}>
          <Icon name="search" size={14}/>
          <Mono size={12}>search agents, txns, hashes</Mono>
          <Mono size={10} color="var(--fg3)">⌘K</Mono>
        </div>
        <Button variant="ghost" size="sm" icon={<Icon name="bell" size={16}/>}>{null}</Button>
        <Button variant="primary" size="sm" icon={<Icon name="plus" size={14}/>}>new agent</Button>
      </div>
    </div>
  );
}
Object.assign(window, { TopBar });
