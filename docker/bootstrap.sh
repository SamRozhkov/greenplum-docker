tee -a /etc/sysctl.conf << EOF
        kernel.shmmax = 5000000000000
        kernel.shmmni = 32768
        kernel.shmall = 40000000000
        kernel.sem = 1000 32768000 1000 32768
        kernel.msgmnb = 1048576
        kernel.msgmax = 1048576
        kernel.msgmni = 32768

        net.core.netdev_max_backlog = 80000
        net.core.rmem_default = 2097152
        net.core.rmem_max = 16777216
        net.core.wmem_max = 16777216

        vm.overcommit_memory = 2
        vm.overcommit_ratio = 95
EOF

tee -a /etc/security/limits.conf << EOF

* soft nofile 524288
* hard nofile 524288
* soft nproc 131072
* hard nproc 131072

EOF