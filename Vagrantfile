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

Vagrant.configure("2") do |config|

  # Create a Vagrant box for the controller node
  config.vm.define "ctrl" do |ctrl|
    # Assign memory and CPUs to the controller node
    ctrl.vm.provider "virtualbox" do |v|
      v.memory = CTRL_MEMORY
      v.cpus = CTRL_CPUS
    end
    # Add private network for the controller node
    ctrl.vm.network "private_network", ip: "192.168.56.100"
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
      # Assign memory and CPUs to each worker node
      node.vm.provider "virtualbox" do |v|
        v.memory = NODE_MEMORY
        v.cpus = NODE_CPUS
      end
      # Add private network for each worker node
      node.vm.network "private_network", ip: "192.168.56.#{100 + n}"
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
end
