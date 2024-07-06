### Functional Description

This project is designed to introduce a delay in the video stream output in the **AXI-STREAM** format.

The framework of this project is displayed below:

![architecture](pic/architecture.png)

The storage memory is the DDR located on the PS side, and the interface can be easily switched to the DDR located on the PL side.

When the video data flows into the system in **AXI-STREAM** format. The data will flow into the forward **FIFO through** the **AXIS-To-FIFO** module, and it will flow out from the backward FIFO through the **FIFO-To-AXIS** module. 

The read-write operation of the forward FIFO and the backward FIFO is controlled by the **AXI4-FIFO-CORE** module. The specified read-write operation is described as follows:

> Once the forward FIFO is filled with more than 1280 data, the AXI4-FIFO-CORE switches to the SEND_DATA stage. It then transfers the 1280 data in burst mode to the DDR through the HP interface.
>
> After a specified number of frames have passed, the backward FIFO read enable signal is activated. Once the backward FIFO is empty, the AXI4-FIFO-CORE switches to the READ_DATA stage and retrieves 1280 data from DDR using burst mode through the HP interface.

### Project Structure

The tree map of this project is shown as below:

> - axi-ddr-axi #vivado project folder
>   - axi-ddr-axi.xpr #vivado project
>   - axi_wr_ddr_tb_behav.wcfg #vivado wave file
> - pic #picture
> - RTL #all necessary code
>   - sim_1 #simulation file
>   - source_1 #source code

After cloning the code using Git, simply open the Vivado project(version 2023.1) and run the simulation.
