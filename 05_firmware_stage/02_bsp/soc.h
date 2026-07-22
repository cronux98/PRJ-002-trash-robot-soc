/* GENERATED-FROM: memory_map.json — DO NOT HAND-EDIT */
/* IP-005 v6 Trash Robot SoC — Peripheral Register Map */
#ifndef SOC_H
#define SOC_H

#include <stdint.h>

/* ── Core ─────────────────────────────── */
#define CPU_ISA           "rv32im"
#define CLOCK_MHZ         33.3
#define MTIME_FREQ_HZ     (33.3000000u)

/* ── Memory Regions ───────────────────── */
#define SRAM_BASE       0x0000
#define SRAM_SIZE       512

#define RESERVED_SRAM_EXP_BASE       0x1000
#define RESERVED_SRAM_EXP_SIZE       4096

#define PERIPH_UART_BASE       0x2000
#define PERIPH_UART_SIZE       4096

#define RESERVED_SPI_BASE       0x3000
#define RESERVED_SPI_SIZE       4096

#define PERIPH_I2C_HX711_BASE       0x4000
#define PERIPH_I2C_HX711_SIZE       4096

#define PERIPH_GPIO_BASE       0x5000
#define PERIPH_GPIO_SIZE       4096

#define PERIPH_TIMER_BASE       0x6000
#define PERIPH_TIMER_SIZE       4096

#define PERIPH_MOTOR_PWM_BASE       0x7000
#define PERIPH_MOTOR_PWM_SIZE       4096

#define PERIPH_ULTRASONIC_BASE       0x8000
#define PERIPH_ULTRASONIC_SIZE       4096

#define PERIPH_WEIGHT_DETECT_BASE       0x9000
#define PERIPH_WEIGHT_DETECT_SIZE       4096

#define PERIPH_I2C_INA219_BASE       0xA000
#define PERIPH_I2C_INA219_SIZE       4096

#define PERIPH_I2C_DS3231_BASE       0xB000
#define PERIPH_I2C_DS3231_SIZE       4096

#define PERIPH_INTERRUPT_CTRL_BASE       0xC000
#define PERIPH_INTERRUPT_CTRL_SIZE       4096

#define PERIPH_WATCHDOG_BASE       0xD000
#define PERIPH_WATCHDOG_SIZE       4096

#define PERIPH_POWER_MGR_BASE       0xE000
#define PERIPH_POWER_MGR_SIZE       4096

#define RESERVED_TOP_BASE       0xF000
#define RESERVED_TOP_SIZE       4096

/* ── IRQ Numbers ────────────────────── */
#define IRQ_TIMER                0    /* pri=0 HIGH */
#define IRQ_UART_RX              1    /* pri=1 HIGH */
#define IRQ_UART_TX              2    /* pri=2 MED  */
#define IRQ_GPIO0                3    /* pri=3 HIGH */
#define IRQ_GPIO1                4    /* pri=4 HIGH */
#define IRQ_GPIO2                5    /* pri=5 MED  */
#define IRQ_MOTOR_PWM            6    /* pri=6 MED  */
#define IRQ_ULTRASONIC_CAPTURE   7    /* pri=7 MED  */
#define IRQ_WEIGHT_DETECT        8    /* pri=8 MED  */
#define IRQ_I2C_HX711            9    /* pri=9 LOW  */
#define IRQ_I2C_INA219           10    /* pri=10 LOW  */
#define IRQ_I2C_DS3231           11    /* pri=11 LOW  */
#define IRQ_WATCHDOG             12    /* pri=12 HIGH */
#define IRQ_POWER_MGR            13    /* pri=13 LOW  */
#define IRQ_GPIO3                14    /* pri=14 LOW  */

/* ── Peripheral Registers ────────────── */

/* UART — 0x2000 */
#define UART_DATA                 (*(volatile uint32_t*)(0x2000 + 0x00))
#define UART_STATUS               (*(volatile uint32_t*)(0x2000 + 0x04))
#define UART_CONTROL              (*(volatile uint32_t*)(0x2000 + 0x08))
#define UART_BAUD_DIV             (*(volatile uint32_t*)(0x2000 + 0x0C))
#define UART_DATA_TXDATA          0x000000FF
#define UART_DATA_RXDATA          0x000000FF
#define UART_STATUS_TX_READY        0x00000001
#define UART_STATUS_RX_VALID        0x00000002
#define UART_CONTROL_TX_ENABLE       0x00000001
#define UART_CONTROL_RX_ENABLE       0x00000002
#define UART_CONTROL_IRQ_ENABLE      0x00000004
#define UART_BAUD_DIV_DIVISOR         0x0000FFFF

/* GPIO — 0x5000 */
#define GPIO_DATA_OUT             (*(volatile uint32_t*)(0x5000 + 0x00))
#define GPIO_DATA_IN              (*(volatile uint32_t*)(0x5000 + 0x04))
#define GPIO_DIRECTION            (*(volatile uint32_t*)(0x5000 + 0x08))
#define GPIO_IRQ_MASK             (*(volatile uint32_t*)(0x5000 + 0x0C))
#define GPIO_DATA_OUT_OUT             0x0000FFFF
#define GPIO_DATA_IN_IN              0x0000FFFF
#define GPIO_DIRECTION_DIR             0x0000FFFF
#define GPIO_IRQ_MASK_MASK            0x0000FFFF

/* TIMER — 0x6000 */
#define TIMER_COUNT                (*(volatile uint32_t*)(0x6000 + 0x00))
#define TIMER_COMPARE              (*(volatile uint32_t*)(0x6000 + 0x04))
#define TIMER_CONTROL              (*(volatile uint32_t*)(0x6000 + 0x08))
#define TIMER_COUNT_VALUE           0xFFFFFFFF
#define TIMER_COMPARE_THRESHOLD       0xFFFFFFFF
#define TIMER_CONTROL_ENABLE          0x00000001
#define TIMER_CONTROL_IRQ_ENABLE      0x00000002

/* WATCHDOG — 0xD000 */
#define WATCHDOG_MAGIC                (*(volatile uint32_t*)(0xD000 + 0x00))
#define WATCHDOG_TIMEOUT              (*(volatile uint32_t*)(0xD000 + 0x04))
#define WATCHDOG_STATUS               (*(volatile uint32_t*)(0xD000 + 0x08))
#define WATCHDOG_MAGIC_KEY             0xFFFFFFFF
#define WATCHDOG_TIMEOUT_CYCLES          0xFFFFFFFF
#define WATCHDOG_STATUS_TRIPPED         0x00000001

/* MOTOR_PWM — 0x7000 */
#define MOTOR_PWM_PHASE_A              (*(volatile uint32_t*)(0x7000 + 0x00))
#define MOTOR_PWM_PHASE_B              (*(volatile uint32_t*)(0x7000 + 0x04))
#define MOTOR_PWM_PHASE_C              (*(volatile uint32_t*)(0x7000 + 0x08))
#define MOTOR_PWM_PHASE_D              (*(volatile uint32_t*)(0x7000 + 0x0C))
#define MOTOR_PWM_PHASE_A_PHASE           0x00000001
#define MOTOR_PWM_PHASE_A_ENABLE          0x00000002
#define MOTOR_PWM_PHASE_B_PHASE           0x00000001
#define MOTOR_PWM_PHASE_B_ENABLE          0x00000002
#define MOTOR_PWM_PHASE_C_PHASE           0x00000001
#define MOTOR_PWM_PHASE_C_ENABLE          0x00000002
#define MOTOR_PWM_PHASE_D_PHASE           0x00000001
#define MOTOR_PWM_PHASE_D_ENABLE          0x00000002

/* I2C_HX711 — 0x4000 */
#define I2C_HX711_DATA                 (*(volatile uint32_t*)(0x4000 + 0x00))
#define I2C_HX711_STATUS               (*(volatile uint32_t*)(0x4000 + 0x04))
#define I2C_HX711_ADDR                 (*(volatile uint32_t*)(0x4000 + 0x08))
#define I2C_HX711_CONTROL              (*(volatile uint32_t*)(0x4000 + 0x0C))
#define I2C_HX711_DATA_TXDATA          0x000000FF
#define I2C_HX711_DATA_RXDATA          0x000000FF
#define I2C_HX711_STATUS_BUSY            0x00000001
#define I2C_HX711_STATUS_ACK             0x00000002
#define I2C_HX711_ADDR_SLAVE_ADDR      0x0000007F
#define I2C_HX711_CONTROL_START           0x00000001
#define I2C_HX711_CONTROL_STOP            0x00000002

/* I2C_INA219 — 0xA000 */
#define I2C_INA219_DATA                 (*(volatile uint32_t*)(0xA000 + 0x00))
#define I2C_INA219_STATUS               (*(volatile uint32_t*)(0xA000 + 0x04))
#define I2C_INA219_ADDR                 (*(volatile uint32_t*)(0xA000 + 0x08))
#define I2C_INA219_CONTROL              (*(volatile uint32_t*)(0xA000 + 0x0C))
#define I2C_INA219_DATA_TXDATA          0x000000FF
#define I2C_INA219_DATA_RXDATA          0x000000FF
#define I2C_INA219_STATUS_BUSY            0x00000001
#define I2C_INA219_STATUS_ACK             0x00000002
#define I2C_INA219_ADDR_SLAVE_ADDR      0x0000007F
#define I2C_INA219_CONTROL_START           0x00000001
#define I2C_INA219_CONTROL_STOP            0x00000002

/* I2C_DS3231 — 0xB000 */
#define I2C_DS3231_DATA                 (*(volatile uint32_t*)(0xB000 + 0x00))
#define I2C_DS3231_STATUS               (*(volatile uint32_t*)(0xB000 + 0x04))
#define I2C_DS3231_ADDR                 (*(volatile uint32_t*)(0xB000 + 0x08))
#define I2C_DS3231_CONTROL              (*(volatile uint32_t*)(0xB000 + 0x0C))
#define I2C_DS3231_DATA_TXDATA          0x000000FF
#define I2C_DS3231_DATA_RXDATA          0x000000FF
#define I2C_DS3231_STATUS_BUSY            0x00000001
#define I2C_DS3231_STATUS_ACK             0x00000002
#define I2C_DS3231_ADDR_SLAVE_ADDR      0x0000007F
#define I2C_DS3231_CONTROL_START           0x00000001
#define I2C_DS3231_CONTROL_STOP            0x00000002

/* ULTRASONIC_CAPTURE — 0x8000 */
#define ULTRASONIC_CAPTURE_TRIGGER              (*(volatile uint32_t*)(0x8000 + 0x00))
#define ULTRASONIC_CAPTURE_ECHO_COUNT_A         (*(volatile uint32_t*)(0x8000 + 0x04))
#define ULTRASONIC_CAPTURE_ECHO_COUNT_B         (*(volatile uint32_t*)(0x8000 + 0x08))
#define ULTRASONIC_CAPTURE_CONTROL              (*(volatile uint32_t*)(0x8000 + 0x0C))
#define ULTRASONIC_CAPTURE_TRIGGER_PULSE           0x00000001
#define ULTRASONIC_CAPTURE_ECHO_COUNT_A_US              0xFFFFFFFF
#define ULTRASONIC_CAPTURE_ECHO_COUNT_B_US              0xFFFFFFFF
#define ULTRASONIC_CAPTURE_CONTROL_ENABLE          0x00000001
#define ULTRASONIC_CAPTURE_CONTROL_IRQ_ENABLE      0x00000002

/* WEIGHT_DETECT — 0x9000 */
#define WEIGHT_DETECT_THRESHOLD            (*(volatile uint32_t*)(0x9000 + 0x00))
#define WEIGHT_DETECT_STATUS               (*(volatile uint32_t*)(0x9000 + 0x04))
#define WEIGHT_DETECT_CONTROL              (*(volatile uint32_t*)(0x9000 + 0x08))
#define WEIGHT_DETECT_THRESHOLD_VALUE           0xFFFFFFFF
#define WEIGHT_DETECT_STATUS_DETECTED        0x00000001
#define WEIGHT_DETECT_STATUS_CURRENT         0xFFFFFFFE
#define WEIGHT_DETECT_CONTROL_ENABLE          0x00000001
#define WEIGHT_DETECT_CONTROL_IRQ_ENABLE      0x00000002

/* INTERRUPT_CTRL — 0xC000 */
#define INTERRUPT_CTRL_PENDING              (*(volatile uint32_t*)(0xC000 + 0x00))
#define INTERRUPT_CTRL_MASK                 (*(volatile uint32_t*)(0xC000 + 0x04))
#define INTERRUPT_CTRL_PRIORITY             (*(volatile uint32_t*)(0xC000 + 0x08))
#define INTERRUPT_CTRL_PENDING_PENDING         0x0000FFFF
#define INTERRUPT_CTRL_MASK_MASK            0x0000FFFF
#define INTERRUPT_CTRL_PRIORITY_ACTIVE_IRQ      0x0000000F

/* POWER_MGR — 0xE000 */
#define POWER_MGR_STATE                (*(volatile uint32_t*)(0xE000 + 0x00))
#define POWER_MGR_CLK_GATE             (*(volatile uint32_t*)(0xE000 + 0x04))
#define POWER_MGR_STATE_MODE            0x00000003
#define POWER_MGR_CLK_GATE_MASK            0x0000FFFF

/* ── Inline Access Helpers ──────────── */
#define REG_WRITE(addr, val)  (*(volatile uint32_t*)(addr) = (val))
#define REG_READ(addr)         (*(volatile uint32_t*)(addr))

static inline void reg_set(uint32_t addr, uint32_t mask) {
    REG_WRITE(addr, REG_READ(addr) | mask);
}
static inline void reg_clear(uint32_t addr, uint32_t mask) {
    REG_WRITE(addr, REG_READ(addr) & ~mask);
}

#endif /* SOC_H */
