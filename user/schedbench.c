#include <stdio.h>
#include <ulib.h>

struct bench_task {
    const char *name;
    int loops;
    int yield_mod;
    uint32_t prio;
};

static volatile uint32_t sink = 1;

static void
busy_work(int loops, int yield_mod)
{
    for (int i = 0; i < loops; i++)
    {
        sink = sink * 1664525U + 1013904223U;
        if (yield_mod > 0 && (i % yield_mod) == 0)
        {
            yield();
        }
    }
}

int
main(void)
{
    struct bench_task tasks[] = {
        {"cpu-short", 60000, 0, 5},
        {"io-heavy", 90000, 40, 5},
        {"cpu-long", 200000, 0, 5},
        {"high-prio", 150000, 120, 10},
    };
    int ntasks = sizeof(tasks) / sizeof(tasks[0]);

    uint32_t global_start = gettime_msec();
    for (int i = 0; i < ntasks; i++)
    {
        int pid = fork();
        if (pid == 0)
        {
            lab6_setpriority(tasks[i].prio);
            uint32_t start = gettime_msec();
            busy_work(tasks[i].loops, tasks[i].yield_mod);
            uint32_t end = gettime_msec();
            cprintf("[bench] %-8s pid=%d prio=%u start=%ums end=%ums turnaround=%ums\n",
                    tasks[i].name, getpid(), tasks[i].prio, start, end, end - start);
            exit(0);
        }
        assert(pid > 0);
    }

    while (wait() == 0)
    {
        ;
    }

    uint32_t global_end = gettime_msec();
    cprintf("[bench] all done total=%ums for %d tasks\n", global_end - global_start, ntasks);
    return 0;
}
