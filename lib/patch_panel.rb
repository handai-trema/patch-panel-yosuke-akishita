# Software patch-panel.
class PatchPanel < Trema::Controller
  def start(_args)
    @patch = Hash.new { |p1,p2| p1[p2]=[]  } #See reference : http://qiita.com/shibukk/items/35c4859e7ca84a427e25
    @mirror = Hash.new { |p1,p2| p1[p2]=[] }
    logger.info "#{name} started."
  end

  def switch_ready(dpid)
    @patch[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end
    @mirror[dpid].each do |port_a, mirror_port|
      #delete_mirror_entries dpid, port_a, mirror_port
      add_mirror_entries dpid, port_a, mirror_port
    end
  end

  def create_patch(dpid, port_a, port_b)
    add_flow_entries dpid, port_a, port_b
    @patch[dpid] << [port_a, port_b].sort
  end

  def delete_patch(dpid, port_a, port_b)
    delete_flow_entries dpid, port_a, port_b
    @patch[dpid] -= [port_a, port_b].sort
  end

  def create_mirror(dpid, port_a, mirror_port)
    add_mirror_entries dpid, port_a, mirror_port
    @mirror[dpid] << [port_a, mirror_port].sort
  end

  def list()
    list_temp = Array.new()
    list_temp << @patch
    list_temp << @mirror
    return list_temp
  end

  private

  def add_flow_entries(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_b),
                      actions: SendOutPort.new(port_a))
  end

  def delete_flow_entries(dpid, port_a, port_b)
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))
  end

  def add_mirror_entries(dpid, port_source, mirror_port)
    @patch[dpid].each do |port_a, port_b|
      port_t=nil
      port_t=port_b if port_a==port_source
      port_t=port_a if port_b==port_source
      if port_t!=nil then
        logger.info "port#{mirror_port}:Mirror of port#{port_source} is added."
        send_flow_mod_delete(dpid, match: Match.new(in_port: port_source))
        send_flow_mod_delete(dpid, match: Match.new(in_port: port_t))
        send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_source),
                      actions:[ 
                        SendOutPort.new(port_t),
                        SendOutPort.new(mirror_port)
                    ])
        send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_t),
                      actions:[ 
                        SendOutPort.new(port_source),
                        SendOutPort.new(mirror_port)
                    ])
      end
    end
  end

end
