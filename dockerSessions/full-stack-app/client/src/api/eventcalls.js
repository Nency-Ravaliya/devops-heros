import api from "./config.js";

export const get_events = async () => {
    try {
        const events = await api.get("/api/events")
        return events.data
    } catch (e) {
        return e.response?.data?.message || "error at eventcalls.js/get_events without message"
    }
}

export const get_event = async (id) => {
    try {
        const event = await api.get(`/api/events/${id}`)
        return event.data
    } catch (e) {
        return e.response?.data?.message || "error at eventcalls.js/get_events without message"
    }
}