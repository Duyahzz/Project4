import { Link, useNavigate } from 'react-router-dom'
import { useData } from '../hooks/useData'
import { useToast } from '../hooks/useToast'

export function RegisterPage() {
  const { users } = useData()
  const { push } = useToast()
  const navigate = useNavigate()

  const totalUsers = users.length

  const goToLogin = () => {
    push('info', 'Please sign in with an account provided by the school administrator.')
    navigate('/login')
  }

  return (
    <div className="max-w-2xl mx-auto bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <h1 className="text-2xl font-bold text-slate-900">Registration Disabled</h1>
      <p className="text-sm text-slate-600 mt-2">
        Account request and approval workflow has been removed. New accounts are now managed
        directly by school administration.
      </p>
      <p className="text-sm text-slate-500 mt-4">
        Existing accounts in system: <span className="font-semibold text-slate-700">{totalUsers}</span>
      </p>

      <div className="mt-6 flex items-center justify-between gap-3">
        <p className="text-sm text-slate-500">
          Already have credentials?{' '}
          <Link to="/login" className="text-indigo-600 font-semibold hover:underline">
            Login here
          </Link>
        </p>
        <button
          type="button"
          onClick={goToLogin}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-5 py-2"
        >
          Go to Login
        </button>
      </div>
    </div>
  )
}
