import dpsimpy

from multiprocessing import Process, Queue


def dpsim0():
    sim_name = "ShmemDistributed0"
    time_step = 0.001
    final_time = 10

    n1 = dpsimpy.dp.SimNode('n1', dpsimpy.PhaseType.Single, [10])
    n2 = dpsimpy.dp.SimNode('n2', dpsimpy.PhaseType.Single, [5])

    evs = dpsimpy.dp.ph1.VoltageSource('v_intf', dpsimpy.LogLevel.debug)
    evs.set_parameters(complex(5, 0))

    vs1 = dpsimpy.dp.ph1.VoltageSource('vs_1', dpsimpy.LogLevel.debug)
    vs1.set_parameters(complex(10, 0))

    r12 = dpsimpy.dp.ph1.Resistor('r_12', dpsimpy.LogLevel.debug)
    r12.set_parameters(1)

    evs.connect([dpsimpy.dp.SimNode.gnd, n2])
    vs1.connect([dpsimpy.dp.SimNode.gnd, n1])
    r12.connect([n1, n2])

    sys = dpsimpy.SystemTopology(50, [n1, n2], [evs, vs1, r12])

    dpsimpy.Logger.set_log_dir('logs/' + sim_name)

    logger = dpsimpy.Logger(sim_name)
    logger.log_attribute('v1', 'v', n1)
    logger.log_attribute('v2', 'v', n2)
    logger.log_attribute('r12', 'i_intf', r12)
    logger.log_attribute('ievs', 'i_intf', evs)
    logger.log_attribute('vevs', 'v_intf', evs)

    sim = dpsimpy.RealTimeSimulation(sim_name)
    sim.set_system(sys)
    sim.set_time_step(time_step)
    sim.set_final_time(final_time)


if __name__ == '__main__':
    queue = Queue()
    p_dpsim0 = Process(target=dpsim0)
    
    p_dpsim0.start()
    
    p_dpsim0.join()
    
    print('Both simulations have ended!')

    