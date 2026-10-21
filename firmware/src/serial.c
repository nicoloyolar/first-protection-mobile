#include "serial.h"

#include "stm32f4xx_hal.h"

#define RX_BUFFER_SIZE 512
#define LINE_MAX 256

static UART_HandleTypeDef huart2;

/* Buffer circular llenado por la interrupcion de recepcion. */
static volatile uint8_t rxBuffer[RX_BUFFER_SIZE];
static volatile uint16_t rxHead;
static uint16_t rxTail;

static char line[LINE_MAX];
static size_t lineLen;
static bool lineOverflow;

void serial_init(void)
{
    GPIO_InitTypeDef gpio = {0};

    __HAL_RCC_USART2_CLK_ENABLE();
    __HAL_RCC_GPIOA_CLK_ENABLE();

    gpio.Pin = GPIO_PIN_2 | GPIO_PIN_3;
    gpio.Mode = GPIO_MODE_AF_PP;
    gpio.Pull = GPIO_PULLUP;
    gpio.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    gpio.Alternate = GPIO_AF7_USART2;
    HAL_GPIO_Init(GPIOA, &gpio);

    huart2.Instance = USART2;
    huart2.Init.BaudRate = 115200;
    huart2.Init.WordLength = UART_WORDLENGTH_8B;
    huart2.Init.StopBits = UART_STOPBITS_1;
    huart2.Init.Parity = UART_PARITY_NONE;
    huart2.Init.Mode = UART_MODE_TX_RX;
    huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
    huart2.Init.OverSampling = UART_OVERSAMPLING_16;
    if (HAL_UART_Init(&huart2) != HAL_OK) {
        while (1) {
        }
    }

    __HAL_UART_ENABLE_IT(&huart2, UART_IT_RXNE);
    HAL_NVIC_SetPriority(USART2_IRQn, 1, 0);
    HAL_NVIC_EnableIRQ(USART2_IRQn);
}

void USART2_IRQHandler(void)
{
    /* Leer SR y luego DR limpia RXNE y tambien un eventual overrun. */
    uint32_t sr = USART2->SR;
    if (sr & (USART_SR_RXNE | USART_SR_ORE)) {
        uint8_t byte = (uint8_t)USART2->DR;
        uint16_t next = (uint16_t)((rxHead + 1) % RX_BUFFER_SIZE);
        if (next != rxTail) {
            rxBuffer[rxHead] = byte;
            rxHead = next;
        }
    }
}

bool serial_read_line(char *buf, size_t len)
{
    while (rxTail != rxHead) {
        char c = (char)rxBuffer[rxTail];
        rxTail = (uint16_t)((rxTail + 1) % RX_BUFFER_SIZE);

        if (c == '\r' || c == '\n') {
            bool complete = lineLen > 0 && !lineOverflow;
            size_t n = lineLen;
            lineLen = 0;
            lineOverflow = false;
            if (complete && n < len) {
                for (size_t i = 0; i < n; i++) {
                    buf[i] = line[i];
                }
                buf[n] = '\0';
                return true;
            }
            continue;
        }

        /* Una linea demasiado larga se descarta completa. */
        if (lineLen < LINE_MAX - 1) {
            line[lineLen++] = c;
        } else {
            lineOverflow = true;
        }
    }
    return false;
}

/* Redirige printf a USART2. */
int _write(int file, char *ptr, int len)
{
    (void)file;
    HAL_UART_Transmit(&huart2, (uint8_t *)ptr, (uint16_t)len, HAL_MAX_DELAY);
    return len;
}
