def upgrade ta, td, a, d
  unless a['haproxy'].has_key? 'admin_name'
    a['haproxy']['admin_name'] = ta['haproxy']['admin_name']
  end
  return a, d
end

def downgrade ta, td, a, d
  unless ta['haproxy'].has_key? 'admin_name'
    a['haproxy'].delete('admin_name')
  end
  return a, d
end
