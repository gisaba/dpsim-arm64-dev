# dpsim-arm64-dev
DPSim development environment on arm64

To start an arm64 compatible DPSim development environment, run:

```sh
docker run -v ./logs:/dpsim/logs -it antoniopicone/dpsim-arm64-dev:1.0.1 bash
```

or, if you have time, build from source with the Dockerfile provided:
```bash
docker build -t dpsim-arm64-dev .

# and, once image is ready:

docker run -v ./logs:/dpsim/logs -it dpsim-arm64-dev bash
```


Inside container, run:
```sh
python3.9 test.py
```
Output will be available in log folder on host machine.