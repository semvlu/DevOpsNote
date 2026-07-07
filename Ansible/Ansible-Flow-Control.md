# [Controlling playbook execution: strategies and more](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_strategies.html#controlling-playbook-execution-strategies-and-more)

[Playbook Keywords (cheat sheet)](https://docs.ansible.com/projects/ansible/latest/reference_appendices/playbooks_keywords.html)
## Global
`forks`: Global Parallelism, Max SSH connections. `ansible-playbook -f 30 playbook.yml`

`ansible.cfg`
```
[defaults]
forks = 30
```

## Per play

`serial`: batch size of the exec of the play on the target. Scenario: rolling update. int or percentage.
`strategy`
- `linear`: Task execution is in lockstep per host batch as def by serial. Up to the fork limit of hosts will execute each task at the same time and then the next series of hosts until the batch is done, before going on to the next task.
- `debug`: linear but interactive
- `free`: Task execution is as fast as possible per batch as def by serial. Ansible will not wait for other hosts to finish the current task before queuing more tasks for other hosts. All hosts are still attempted for the current task, but it prevents blocking new tasks for hosts that have already finished.

`order`: Controls the sorting of hosts as they are used for executing the play. options: inventory (default), sorted, reverse_sorted, reverse_inventory, shuffle.

## All levels (Play, Role, Block, Task)
`throttle`: Limit #concurrent tasks. `throttle` < `serial` | `forks`
`run_once`: a task runs only on 1e host in the batch (serial).
