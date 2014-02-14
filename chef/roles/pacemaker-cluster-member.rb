name "pacemaker-cluster-member"
description "Pacemaker cluster member"
run_list(
         "recipe[corosync::default]",
         "recipe[pacemaker::setup]"
)
default_attributes()
override_attributes()
