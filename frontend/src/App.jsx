import { useState } from "react"
import axios from "axios"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

const API = "/api"

const isProd = import.meta.env.MODE === "production"

export default function App() {
  const [results, setResults] = useState({
    ping: "",
    health: "",
    version: "",
    db: "",
    kafka: "",
  })

  const handleRequest = async (endpoint, key) => {
    setResults(prev => ({ ...prev, [key]: "Request in progress..." }))
    try {
      const res = await axios.get(`${API}${endpoint}`)
      const data = res.data

      const formatted =
        typeof data === "object" && data !== null
          ? JSON.stringify(data, null, 2)
          : data === "" || data === null || data === undefined
            ? "No data"
            : String(data)

      setResults(prev => ({ ...prev, [key]: formatted }))
    } catch (err) {
      setResults(prev => ({ ...prev, [key]: `Error: ${err.message}` }))
    }
  }

  const actions = [
    { key: "ping", label: "Ping API", endpoint: "/" },
    { key: "health", label: "Health Check", endpoint: "/health" },
    { key: "version", label: "Get Version", endpoint: "/version" },
    { key: "db", label: "DB Test", endpoint: "/db-test" },

    ...(!isProd
      ? [{ key: "kafka", label: "Send to Kafka", endpoint: "/send-kafka" }]
      : []),
  ]

  return (
    <div className="grid gap-6 p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold text-center mb-6">
        Vik`s Health-API Dashboard
      </h1>

      {actions.map(({ key, label, endpoint }) => (
        <Card key={key} className="shadow-md border border-gray-300">
          <CardContent className="p-4 space-y-4">
            <Button
              className="w-full h-12 text-base font-medium tracking-normal bg-blue-600 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 text-white rounded-md transition duration-200"
              onClick={() => handleRequest(endpoint, key)}
            >
              {label}
            </Button>
            <pre className="whitespace-pre-wrap text-sm leading-snug bg-gray-100 p-3 rounded-md w-full">
              {results[key]}
            </pre>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
