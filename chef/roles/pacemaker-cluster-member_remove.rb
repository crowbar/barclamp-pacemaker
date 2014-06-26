name "pacemaker-cluster-member_remove"
description "Remove cluster member from cluster"
run_list(
         "recipe[pacemaker::remove_from_cluster]"
)
default_attributes()
override_attributes()
