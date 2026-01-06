const gb1 = 1024 * 1024 * 1024
const mb1 = 1024 * 1024
const kb1 = 1024

export function trafficConvertSpecial(value) {
    if (value >= gb1) {
        return value / gb1 / 1000 + 5
    } else if (value >= mb1) {
        return value / mb1 / 1000 + 4
    } else if (value >= kb1) {
        return value / kb1 / 1000 + 3
    } else {
        return value / kb1 + 2
    }
}

export function trafficConvertUnit(value) {

    let res = {
        value: value,
        unit: 'GB',
    }
    if (value >= gb1) {
        res.value = Number((value / gb1).toFixed(2))
        res.unit = 'GB'
    } else if (value >= mb1) {
        res.value = Number((value / mb1).toFixed(2))
        res.unit = 'MB'
    } else if (value >= kb1) {
        res.value = Number((value / kb1).toFixed(2))
        res.unit = 'KB'
    }

    return res
}