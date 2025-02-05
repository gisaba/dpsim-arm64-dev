import dpsimpy

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

sim = dpsimpy.RealTimeSimulation(sim_name)
sim.set_system(sys)
sim.set_time_step(time_step)
sim.set_final_time(final_time)

sim.run(1)