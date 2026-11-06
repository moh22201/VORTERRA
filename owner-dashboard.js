(() => {
  const auth = window.vortERRAAuth;
  if (!auth?.rpc) return;

  const $ = (tag, cls, value) => {
    const el = document.createElement(tag);
    if (cls) el.className = cls;
    if (value !== undefined) el.textContent = String(value);
    return el;
  };
  const money = value => Number(value || 0).toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2}) + ' VOR';
  let initInFlight = false;
  let initializedForUser = null;

  async function loadAdminPanel(panel, status) {
    status.textContent = 'Loading platform data…';
    try {
      const [summaryResult, playersResult] = await Promise.all([
        auth.rpc('get_owner_dashboard_summary'),
        auth.rpc('get_owner_dashboard_players', {p_limit: 5000})
      ]);
      if (summaryResult.error) throw summaryResult.error;
      if (playersResult.error) throw playersResult.error;
      const summary = summaryResult.data || {};
      const players = Array.isArray(playersResult.data) ? playersResult.data : [];
      panel.querySelectorAll('.owner-admin-content').forEach(el => el.remove());
      const content = $('div', 'owner-admin-content');
      const metrics = [
        ['Players', summary.players],
        ['Cities', summary.cities],
        ['Owned projects', summary.owned_projects],
        ['Wallet total', money(summary.wallet_total_vor)],
        ['Available VOR', money(summary.wallet_available_vor)],
        ['Reserved VOR', money(summary.wallet_reserved_vor)],
        ['Outstanding loans', money(summary.outstanding_loans_vor)],
        ['Confirmed deposits', summary.confirmed_deposit_count]
      ];
      const grid = $('div', 'dstats');
      metrics.forEach(([label, value]) => {
        const card = $('article', 'dstat');
        card.append($('small', '', label), $('strong', '', value ?? '0'));
        grid.appendChild(card);
      });
      content.appendChild(grid);
      const tablePanel = $('section', 'dpanel');
      const head = $('div', 'dpanelhead');
      head.append($('b', '', 'Registered players'), $('small', '', players.length + ' RECORDS'));
      tablePanel.appendChild(head);
      const body = $('div', 'dpanelbody');
      const table = $('div', 'owner-player-list');
      players.forEach(player => {
        const row = $('article', 'dlisting');
        const info = $('div');
        info.append(
          $('strong', '', player.display_name || 'VORTERRA member'),
          $('small', '', (player.email || '') + ' · ' + (player.user_id || ''))
        );
        const balance = $('div');
        balance.append(
          $('b', '', money(player.wallet_total_vor)),
          $('small', '', 'Available ' + money(player.wallet_available_vor) + ' · Loan ' + money(player.loan_outstanding_vor))
        );
        row.append(info, balance);
        table.appendChild(row);
      });
      if (!players.length) table.appendChild($('p', 'dempty', 'No registered players.'));
      body.appendChild(table);
      tablePanel.appendChild(body);
      content.appendChild(tablePanel);
      panel.appendChild(content);
      status.textContent = 'Platform data updated just now.';
    } catch (error) {
      status.textContent = 'Administrator panel unavailable: ' + (error.message || 'Access denied');
      throw error;
    }
  }

  async function init() {
    if (initInFlight) return;
    initInFlight = true;
    try {
      const {data: sessionData, error: sessionError} = await auth.auth.getSession();
      if (sessionError || !sessionData?.session) return;
      const userId = sessionData.session.user.id;
      if (initializedForUser === userId) return;
      const dashboard = document.getElementById('dashboard');
      const side = dashboard?.querySelector('.dside');
      const main = dashboard?.querySelector('.dmain');
      if (!side || !main) return;

      const button = $('button');
      button.type = 'button';
      button.dataset.view = 'owner-admin';
      button.append($('span', '', '▣'), $('span', '', 'Platform Control'));
      const footer = side.querySelector('footer');
      const panel = $('section', 'dview');
      panel.dataset.panel = 'owner-admin';
      const toolbar = $('div', 'dtoolbar');
      const title = $('div');
      title.append($('h2', '', 'Platform Control Center'), $('p', '', 'Players, cities, projects and platform balances.'));
      const refresh = $('button', 'dprimary', 'Refresh data');
      refresh.type = 'button';
      toolbar.append(title, refresh);
      const status = $('p', 'dmuted', 'Checking administrator permissions…');
      panel.append(toolbar, status);
      const refreshData = () => loadAdminPanel(panel, status).catch(() => {});
      try {
        await loadAdminPanel(panel, status);
      } catch (error) {
        return;
      }
      side.insertBefore(button, footer || null);
      main.appendChild(panel);
      initializedForUser = userId;
      button.addEventListener('click', () => {
        if (typeof window.openDashboardPanel === 'function') window.openDashboardPanel('owner-admin');
        else {
          dashboard.querySelectorAll('.dview').forEach(item => item.classList.toggle('active', item.dataset.panel === 'owner-admin'));
          dashboard.querySelectorAll('[data-view]').forEach(item => item.classList.toggle('active', item.dataset.view === 'owner-admin'));
        }
        refreshData();
      });
      refresh.addEventListener('click', refreshData);
      await refreshData();
    } catch (error) {
      // Non-administrators simply do not receive the administrative navigation item.
    } finally {
      initInFlight = false;
    }
  }

  auth.auth.onAuthStateChange((event, session) => {
    if (session) init();
    else {
      initializedForUser = null;
      document.querySelector('#dashboard [data-view="owner-admin"]')?.remove();
      document.querySelector('#dashboard [data-panel="owner-admin"]')?.remove();
    }
  });
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, {once: true});
  else init();
})();