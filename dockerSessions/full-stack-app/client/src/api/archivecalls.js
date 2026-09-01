import api from "./config.js"

export const get_archives = async () => {
    try {
        const archives = await api.get("/api/archives")
        return archives.data
    } catch (e) {
        return e.response?.data?.message || "error at archivecalls.js/get_archives without message"
    }
}

export const post_archive = async (formdata) => {
    try {
        const response = await api.post("/api/archives", formdata)
        return response.data
    } catch (e) {
        return e
    }
}

export const get_archive = async (query) => {
    try {
        const archive = await api.get(`/api/archives/search?q=${query}`)
        return archive.data
    } catch (e) {
        return e.response?.data?.message || "error at archivecalls.js/get_archive without message"
    }
}