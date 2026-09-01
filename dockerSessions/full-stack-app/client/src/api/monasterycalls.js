import api from "./config.js"

export const get_monasteries = async () => {
    try {
        const monasteries = await api.get("/api/monasteries")
        return monasteries.data
    } catch (e) {
        return e.response?.data?.message || "error at monasterycalls.js/get_monasteries without message"
    }
}

export const get_monastery = async (id) => {
    try {
        const monastery = await api.get(`/api/monasteries/${id}`)
        return monastery.data
    } catch (e) {
        return e.response?.data?.message || "error at monasterycalls.js/get_monastery without message"
    }
}