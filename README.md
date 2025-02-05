# dpsim-arm64-dev
DPSim development environment on arm64

To start an arm64 compatible DPSim development environment, run:

```sh
docker run -v ./logs:/dpsim/logs  -it antoniopicone/dpsim-arm64-dev:1.0.1 bash
```

Inside container, run:
```sh
python3.9 test.py
```
Output will be available in log folder on host machine.