# -*- mode: ruby -*-
# vi: set ft=ruby :

# Box image and version
BOX_IMAGE = "bento/ubuntu-24.04"
BOX_VERSION = "202502.21.0"

# Number of worker nodes
NODE_COUNT = 2

# Number of CPUs and memory for the controller node
CTRL_CPUS = 1
CTRL_MEMORY = 4096

# Number of CPUs and memory for the worker nodes
NODE_CPUS = 2
NODE_MEMORY = 6144

INVENTORY_PATH = "ansible-provisioning/inventory.cfg"
CTRL_IP = "192.168.56.100"
NODE_IPS = (1..NODE_COUNT).map { |n| "192.168.56.#{100 + n}" }

Vagrant.configure("2") do |config|

  # Create a Vagrant box for the controller node
  config.vm.define "ctrl" do |ctrl|
    # Assign memory and CPUs to the controller node
    ctrl.vm.provider "virtualbox" do |v|
      v.memory = CTRL_MEMORY
      v.cpus = CTRL_CPUS
    end
    # Add private network for the controller node
    ctrl.vm.network "private_network", ip: CTRL_IP
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.box = BOX_IMAGE
    ctrl.vm.box_version = BOX_VERSION

    ctrl.vm.provision :ansible do |a|
      a.playbook = "ansible-provisioning/general.yaml"
      a.extra_vars = {
        node_count: NODE_COUNT,
        ctrl_cpus: CTRL_CPUS,
        ctrl_memory: CTRL_MEMORY,
        node_cpus: NODE_CPUS,
        node_memory: NODE_MEMORY
      }
    end
    
    ctrl.vm.provision :ansible do |a|
      a.playbook = "ansible-provisioning/ctrl.yaml"
      a.extra_vars = {
        node_count: NODE_COUNT,
        ctrl_cpus: CTRL_CPUS,
        ctrl_memory: CTRL_MEMORY,
        node_cpus: NODE_CPUS,
        node_memory: NODE_MEMORY
      }
    end
  end

  # Create Vagrant boxes for the worker nodes
  (1..NODE_COUNT).each do |n|
    config.vm.define "node-#{n}" do |node|
    node_ip = NODE_IPS[n - 1]
      # Assign memory and CPUs to each worker node
      node.vm.provider "virtualbox" do |v|
        v.memory = NODE_MEMORY
        v.cpus = NODE_CPUS
      end
      # Add private network for each worker node
      node.vm.network "private_network", ip: node_ip
      node.vm.hostname = "node-#{n}"
      node.vm.box = BOX_IMAGE
      node.vm.box_version = BOX_VERSION

      node.vm.provision :ansible do |a|
        a.playbook = "ansible-provisioning/general.yaml"
        a.extra_vars = {
          node_count: NODE_COUNT,
          node_id: n,
          ctrl_cpus: CTRL_CPUS,
          ctrl_memory: CTRL_MEMORY,
          node_cpus: NODE_CPUS,
          node_memory: NODE_MEMORY
        }
      end
      
      node.vm.provision :ansible do |a|
        a.playbook = "ansible-provisioning/node.yaml"
        a.extra_vars = {
          node_count: NODE_COUNT,
          node_id: n,
          ctrl_cpus: CTRL_CPUS,
          ctrl_memory: CTRL_MEMORY,
          node_cpus: NODE_CPUS,
          node_memory: NODE_MEMORY
        }
      end
    end
  end

  # Create the Ansible inventory file after running `vagrant up`
  config.trigger.after [:up, :reload] do |trigger|
    trigger.name = "Generate Ansible inventory.cfg"
    trigger.ruby do
      # Define the inventory file path
      inventory_file_path = File.join(File.dirname(__FILE__), "ansible-provisioning", "inventory.cfg")
      
      # Create inventory file with controller and node information
      File.open(inventory_file_path, 'w') do |file|
        # Add controller section
        file.puts "[ctrl]"
        file.puts "#{CTRL_IP}"
        file.puts ""
        
        # Add nodes section
        file.puts "[nodes]"
        NODE_IPS.each_with_index do |ip, i|
          file.puts "#{ip}"
        end
      end
      
      puts "Successfully created inventory file at #{inventory_file_path}"
    end
  end
end
